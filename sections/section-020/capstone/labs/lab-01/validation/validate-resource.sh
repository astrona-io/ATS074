#!/usr/bin/env bash
# Check: the Collector receives data with service.name shuttle and the environment staging.
set -uo pipefail

NS=starfleet

# Value of one environment variable on the shuttle container (empty if unset).
deploy_env() {
  kubectl -n "$NS" get deploy shuttle -o json | jq -r --arg name "$1" '.spec.template.spec.containers[0].env[]? | select(.name==$name) | .value'
}

# Start-up line of the running shuttle pod.
pipeline_line() {
  kubectl -n "$NS" logs deploy/shuttle 2>/dev/null | grep "pipeline:" | tail -1
}

# The last two minutes of Collector output.
collector_recent() {
  kubectl -n "$NS" logs deploy/collector --since=120s 2>/dev/null
}

# Run a check function every 2 seconds for up to about 2 minutes.
wait_until() {
  local attempt
  for attempt in $(seq 1 60); do
    if "$@"; then
      return 0
    fi
    sleep 2
  done
  return 1
}

resource_is_right() {
  local output
  output="$(collector_recent)"
  printf '%s' "$output" | grep -q "service.name: Str(shuttle)" \
    && printf '%s' "$output" | grep -q "deployment.environment.name: Str(staging)"
}

if wait_until resource_is_right; then
  echo "PASS: recent Collector output has service.name shuttle and environment staging"
  exit 0
fi
echo "FAIL: recent Collector output lacks service.name shuttle or deployment.environment.name staging"
exit 1
