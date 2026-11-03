#!/usr/bin/env bash
# Check: spans named dispatch reach the collector (the sampler keeps them).
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

spans_arrive() {
  fresh_logs 30 | grep -Eq '^ *Name *: *dispatch *$'
}

if wait_until spans_arrive; then
  echo "PASS: fresh spans named dispatch reach the collector"
  exit 0
fi
echo "FAIL: no span named dispatch reached the collector in the last 30 seconds. Check the sampler."
exit 1
