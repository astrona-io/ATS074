#!/usr/bin/env bash
# Check: the shuttle logs at INFO or above, and no fresh DEBUG record arrives.
set -uo pipefail

NS=starfleet
# The shuttle needs a minute to install the SDK after every change, so every
# check polls (up to about 150 seconds) for fresh records in the collector log.
fresh_logs() { kubectl -n "$NS" logs deploy/collector --since="${1:-20}s" 2>/dev/null; }
wait_until() {
  local check="$1" i
  for i in $(seq 1 50); do
    if "$check"; then return 0; fi
    sleep 3
  done
  return 1
}

level="$(kubectl -n "$NS" get deployment shuttle -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name == "SHUTTLE_LOG_LEVEL") | .value' | head -n 1)"
case "$(echo "$level" | tr a-z A-Z)" in
  INFO|WARN|WARNING|ERROR|CRITICAL|FATAL) ;;
  *)
    echo "FAIL: SHUTTLE_LOG_LEVEL is '$level', expected INFO or higher"
    exit 1
    ;;
esac

no_debug_records() {
  local text
  text="$(fresh_logs 20)"
  echo "$text" | grep -q 'LogRecord #' || return 1
  ! echo "$text" | grep -q 'SeverityText: DEBUG'
}

if wait_until no_debug_records; then
  echo "PASS: fresh log records arrive and none has severity DEBUG"
  exit 0
fi
echo "FAIL: DEBUG records still reach the collector, or no fresh records arrive"
exit 1
