#!/usr/bin/env bash
# Check: the Collector receives shuttle.requests as a delta sum.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

# poll_log SINCE TESTFUNCTION: read the recent Collector log until the test passes (up to 120 seconds).
poll_log() {
  local since="$1" test_fn="$2" i log
  for i in $(seq 1 24); do
    log="$(kubectl -n starfleet logs deploy/collector --since="$since" 2>/dev/null || true)"
    if "$test_fn" "$log"; then
      return 0
    fi
    sleep 5
  done
  return 1
}

requests_are_delta() {
  local log="$1"
  echo "$log" | grep -A8 'Name: shuttle.requests' | grep -q 'AggregationTemporality: Delta'
}
if poll_log 40s requests_are_delta; then
  echo "PASS: shuttle.requests arrives with AggregationTemporality: Delta"
  exit 0
fi
echo "FAIL: in the last 40 seconds the Collector did not receive shuttle.requests with AggregationTemporality: Delta. Wait for the rollout and try again."
exit 1
