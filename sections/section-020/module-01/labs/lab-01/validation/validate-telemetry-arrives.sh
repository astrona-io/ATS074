#!/usr/bin/env bash
# Check: spans, metrics and logs from the scope starfleet.navigation reach the Collector.
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

all_signals_arrive() {
  local output
  output="$(collector_recent)"
  printf '%s' "$output" | grep -q "InstrumentationScope starfleet.navigation" \
    && printf '%s' "$output" | grep -q "plot-course" \
    && printf '%s' "$output" | grep -q "shuttle.jumps" \
    && printf '%s' "$output" | grep -q "course plotted"
}

if wait_until all_signals_arrive; then
  echo "PASS: spans, metrics and log records from starfleet.navigation arrive"
  exit 0
fi
echo "FAIL: recent Collector output lacks the scope, the span plot-course, the metric shuttle.jumps or the log record"
exit 1
