#!/usr/bin/env bash
# Check: the scan span in the Collector log has a non-empty parent ID.
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

for _ in $(seq 1 24); do
  if recent_logs | awk '
    /^ *Parent ID *:/ { sub(/^[^:]*: ?/, ""); parent = $0 }
    /^ *Name *: / { sub(/^[^:]*: ?/, ""); if ($0 == "scan" && parent != "") found = 1 }
    END { exit found ? 0 : 1 }'; then
    echo "PASS: a scan span has a parent span"
    exit 0
  fi
  sleep 5
done
echo "FAIL: no scan span with a parent ID in the last 2 minutes"
exit 1
