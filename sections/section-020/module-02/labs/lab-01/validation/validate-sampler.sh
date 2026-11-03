#!/usr/bin/env bash
# Check: a parent-based sampler runs and spans reach the Collector.
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

has_parent_based_sampler() {
  pipeline_line | grep -q "sampler=ParentBased{"
}
spans_arrive() {
  collector_recent | grep -q "plot-course"
}

if ! wait_until has_parent_based_sampler; then
  echo "FAIL: the running pod does not print a ParentBased sampler: $(pipeline_line)"
  exit 1
fi

# A ratio below 1 would drop root traces.
if [ "$(deploy_env OTEL_TRACES_SAMPLER)" = "parentbased_traceidratio" ]; then
  ratio="$(deploy_env OTEL_TRACES_SAMPLER_ARG)"
  if ! awk -v r="$ratio" 'BEGIN { exit !(r + 0 >= 1) }'; then
    echo "FAIL: parentbased_traceidratio with ratio '$ratio' does not record every root trace"
    exit 1
  fi
fi

if wait_until spans_arrive; then
  echo "PASS: a parent-based sampler runs and the span plot-course arrives"
  exit 0
fi
echo "FAIL: recent Collector output has no plot-course span"
exit 1
