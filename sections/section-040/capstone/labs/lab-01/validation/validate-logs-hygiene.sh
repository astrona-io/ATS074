#!/usr/bin/env bash
# Check: fresh log records arrive, none has severity DEBUG and none carries the
# authorization header or the e-mail address.
set -uo pipefail

NS=starfleet
# The shuttle needs a minute to install the SDK after every change, so every
# check polls (up to about 150 seconds) for fresh telemetry in the collector log.
fresh_logs() { kubectl -n "$NS" logs deploy/collector --since="${1:-20}s" 2>/dev/null; }
wait_until() {
  local check="$1" i
  for i in $(seq 1 50); do
    if "$check"; then return 0; fi
    sleep 3
  done
  return 1
}

clean_records() {
  local text
  text="$(fresh_logs 20)"
  echo "$text" | grep -q 'LogRecord #' || return 1
  ! echo "$text" | grep -q 'SeverityText: DEBUG' || return 1
  ! echo "$text" | grep -Eq 'request.authorization|customer.email|Bearer '
}

if wait_until clean_records; then
  echo "PASS: fresh log records arrive, none is DEBUG and none carries sensitive attributes"
  exit 0
fi
echo "FAIL: DEBUG records or sensitive attributes still reach the collector, or no fresh log records arrive"
exit 1
