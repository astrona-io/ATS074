#!/usr/bin/env bash
# Check: the shuttle names its service. The Deployment sets OTEL_SERVICE_NAME=shuttle and fresh spans in the Collector log carry service.name shuttle.
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

name="$(shuttle_env OTEL_SERVICE_NAME)"
if [ "$name" != "shuttle" ]; then
  echo "FAIL: OTEL_SERVICE_NAME is '${name}'; set it to shuttle"
  exit 1
fi
if wait_log 'service\.name: Str\(shuttle\)'; then
  echo "PASS: the Collector received spans with service.name shuttle"
  exit 0
fi
echo "FAIL: no span with service.name shuttle in the last 2 minutes; wait for the new pod to start"
exit 1
