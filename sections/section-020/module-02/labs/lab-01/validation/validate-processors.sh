#!/usr/bin/env bash
# Check: the running pod uses crew-tag then batch with a two second delay.
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

delay="$(deploy_env OTEL_BSP_SCHEDULE_DELAY)"
if [ "$delay" != "2000" ]; then
  echo "FAIL: OTEL_BSP_SCHEDULE_DELAY is '$delay', expected 2000"
  exit 1
fi

has_processors() {
  pipeline_line | grep -q "processors=crew-tag,batch "
}

if wait_until has_processors; then
  echo "PASS: the running pod uses crew-tag,batch with a 2000 ms delay"
  exit 0
fi
echo "FAIL: the running pod does not print processors=crew-tag,batch: $(pipeline_line)"
exit 1
