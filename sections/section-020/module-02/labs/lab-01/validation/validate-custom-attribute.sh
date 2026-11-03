#!/usr/bin/env bash
# Check: spans at the Collector carry starfleet.crew.size with the value 4.
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

has_attribute() {
  collector_recent | grep -q "starfleet.crew.size: Int(4)"
}

if wait_until has_attribute; then
  echo "PASS: spans carry starfleet.crew.size=4"
  exit 0
fi
echo "FAIL: recent Collector output has no starfleet.crew.size: Int(4)"
exit 1
