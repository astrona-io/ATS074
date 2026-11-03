#!/usr/bin/env bash
# Check: crew-tag then batch run with a parent-based ratio sampler at 0.5.
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

if [ "$(deploy_env OTEL_TRACES_SAMPLER)" != "parentbased_traceidratio" ]; then
  echo "FAIL: OTEL_TRACES_SAMPLER must be parentbased_traceidratio"
  exit 1
fi
if ! awk -v r="$(deploy_env OTEL_TRACES_SAMPLER_ARG)" 'BEGIN { exit !(r != "" && r + 0 == 0.5) }'; then
  echo "FAIL: OTEL_TRACES_SAMPLER_ARG must be 0.5"
  exit 1
fi

pipeline_is_right() {
  local line
  line="$(pipeline_line)"
  printf '%s' "$line" | grep -q "processors=crew-tag,batch " \
    && printf '%s' "$line" | grep -q "TraceIdRatioBased{0.5}"
}
attribute_arrives() {
  collector_recent | grep -q "starfleet.crew.size: Int(4)"
}

if ! wait_until pipeline_is_right; then
  echo "FAIL: the running pod does not show crew-tag,batch and TraceIdRatioBased{0.5}: $(pipeline_line)"
  exit 1
fi
if wait_until attribute_arrives; then
  echo "PASS: crew-tag,batch and the 0.5 ratio sampler run, and spans carry starfleet.crew.size"
  exit 0
fi
echo "FAIL: recent Collector output has no starfleet.crew.size: Int(4)"
exit 1
