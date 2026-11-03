#!/usr/bin/env bash
# Check: the sampler no longer drops every trace, and dock, scan and report spans reach the Collector.
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

sampler="$(shuttle_env OTEL_TRACES_SAMPLER)"
arg="$(shuttle_env OTEL_TRACES_SAMPLER_ARG)"
case "$sampler" in
  ""|always_on|parentbased_always_on) ;;
  traceidratio|parentbased_traceidratio)
    case "$arg" in
      1|1.0|1.00) ;;
      *) echo "FAIL: sampler $sampler with argument '${arg}' still drops traces"; exit 1 ;;
    esac ;;
  *) echo "FAIL: sampler '${sampler}' drops traces; use always_on or parentbased_always_on"; exit 1 ;;
esac
for span in dock scan report; do
  if ! wait_log "^ +Name +: ${span}\$"; then
    echo "FAIL: no span named $span in the Collector log in the last 2 minutes"
    exit 1
  fi
done
echo "PASS: dock, scan and report spans reach the Collector"
exit 0
