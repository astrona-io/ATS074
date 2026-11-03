#!/usr/bin/env bash
# Check: the Collector receives exemplars on the histogram.
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

histogram_has_exemplars() {
  local log="$1"
  echo "$log" | awk '/Name: shuttle.request.duration/{f=1} f && /Exemplars:/{found=1} /Name: shuttle.requests|Name: shuttle.queue.depth|Name: shuttle.fuel.level/{f=0} END{exit found?0:1}'
}
if poll_log 40s histogram_has_exemplars; then
  echo "PASS: shuttle.request.duration data points carry exemplars"
  exit 0
fi
echo "FAIL: in the last 40 seconds no shuttle.request.duration data point carried exemplars. Check OTEL_METRICS_EXEMPLAR_FILTER and wait for the rollout."
exit 1
