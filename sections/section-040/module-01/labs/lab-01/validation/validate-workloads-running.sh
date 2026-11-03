#!/usr/bin/env bash
# Check: the collector and shuttle Deployments are available and not replaced.
set -uo pipefail

recent_logs() { kubectl -n starfleet logs deploy/collector --since=120s 2>/dev/null; }
# Poll the Collector log for up to about 2 minutes. $1 is an awk or grep -E check run by the caller.
wait_log() {
  for _ in $(seq 1 24); do
    if recent_logs | grep -Eq "$1"; then return 0; fi
    sleep 5
  done
  return 1
}
shuttle_env() {
  kubectl -n starfleet get deployment shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" ".spec.template.spec.containers[0].env[]? | select(.name==\$n) | .value"
}

fail=0
for name in collector shuttle; do
  ready="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica"
    fail=1
  fi
done
image="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
if [ "$image" != "python:3.12-slim" ]; then
  echo "FAIL: the shuttle image is $image; keep python:3.12-slim"
  fail=1
fi
cimage="$(kubectl -n starfleet get deployment collector -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
case "$cimage" in
  otel/opentelemetry-collector-contrib:*) ;;
  *) echo "FAIL: the collector image is $cimage"; fail=1 ;;
esac
[ "$fail" -eq 0 ] && echo "PASS: collector and shuttle are available"
exit "$fail"
