#!/usr/bin/env bash
# Check: no fresh log record carries the authorization header or the e-mail.
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

payload="$(kubectl -n "$NS" get deployment shuttle -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name == "SHUTTLE_LOG_PAYLOAD") | .value' | head -n 1)"
if [ "$(echo "$payload" | tr A-Z a-z)" = "true" ]; then
  echo "FAIL: SHUTTLE_LOG_PAYLOAD is still true"
  exit 1
fi

clean_records() {
  local text
  text="$(fresh_logs 20)"
  echo "$text" | grep -q 'LogRecord #' || return 1
  ! echo "$text" | grep -Eq 'request.authorization|customer.email|Bearer '
}

if wait_until clean_records; then
  echo "PASS: fresh log records arrive and none carries request.authorization or customer.email"
  exit 0
fi
echo "FAIL: sensitive attributes still reach the collector, or no fresh records arrive"
exit 1
