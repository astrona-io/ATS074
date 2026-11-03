#!/usr/bin/env bash
# Check: the Collector receives the corrected resource, a delta sum, exemplars and a log record with a trace ID.
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

everything_arrives() {
  local log="$1"
  echo "$log" | grep -q 'service.name: Str(shuttle)' || { MISSING="resource service.name"; return 1; }
  if echo "$log" | grep -q 'request.id: Str'; then MISSING="request.id still on the resource"; return 1; fi
  echo "$log" | grep -A8 'Name: shuttle.requests' | grep -q 'AggregationTemporality: Delta' || { MISSING="delta sum for shuttle.requests"; return 1; }
  echo "$log" | grep -q 'Exemplars:' || { MISSING="exemplars"; return 1; }
  echo "$log" | awk '/^ResourceSpans|^ResourceMetrics/{rec=0} /^LogRecord #/{rec=1} rec && /Trace ID: [0-9a-f]+/{found=1} END{exit found?0:1}' || { MISSING="a log record with a trace ID"; return 1; }
  return 0
}
MISSING=""
if poll_log 40s everything_arrives; then
  echo "PASS: the Collector log shows resource, delta sum, exemplars and a correlated log record"
  exit 0
fi
echo "FAIL: in the last 40 seconds the Collector log was missing: ${MISSING:-unknown}. Wait for the rollout and try again."
exit 1
