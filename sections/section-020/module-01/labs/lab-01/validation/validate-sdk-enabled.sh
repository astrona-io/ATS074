#!/usr/bin/env bash
# Check: the SDK is not disabled and the running pod gets a real SDK tracer.
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

disabled="$(deploy_env OTEL_SDK_DISABLED | tr '[:upper:]' '[:lower:]')"
if [ "$disabled" = "true" ]; then
  echo "FAIL: OTEL_SDK_DISABLED is still true on the shuttle Deployment"
  exit 1
fi

has_real_tracer() {
  pipeline_line | grep -q "tracer=Tracer "
}

if wait_until has_real_tracer; then
  echo "PASS: the running shuttle pod uses the SDK tracer"
  exit 0
fi
echo "FAIL: the running pod does not print tracer=Tracer: $(pipeline_line)"
exit 1
