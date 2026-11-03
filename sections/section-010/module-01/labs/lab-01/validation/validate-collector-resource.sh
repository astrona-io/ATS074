#!/usr/bin/env bash
# Check: the Collector received telemetry with the corrected resource and no request.id.
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

resource_is_correct() {
  local log="$1"
  echo "$log" | grep -q 'service.name: Str(shuttle)' || return 1
  echo "$log" | grep -q 'service.namespace: Str(starfleet)' || return 1
  echo "$log" | grep -q 'deployment.environment.name: Str(training)' || return 1
  if echo "$log" | grep -q 'request.id: Str'; then
    return 1
  fi
  return 0
}
if poll_log 30s resource_is_correct; then
  echo "PASS: the Collector log shows the corrected resource"
  exit 0
fi
echo "FAIL: in the last 30 seconds the Collector did not receive a resource with service.name shuttle, service.namespace starfleet and deployment.environment.name training, without request.id. Wait for the rollout and try again."
exit 1
