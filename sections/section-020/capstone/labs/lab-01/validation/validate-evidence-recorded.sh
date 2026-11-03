#!/usr/bin/env bash
# Check: the ConfigMap composability-evidence matches the pod log and the Collector log.
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

fail=0
read_key() {
  kubectl -n "$NS" get configmap composability-evidence -o json 2>/dev/null | jq -r --arg key "$1" '.data[$key] // empty'
}

if ! kubectl -n "$NS" get configmap composability-evidence >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap composability-evidence does not exist in $NS"
  exit 1
fi

if [ "$(read_key tracer-class)" != "Tracer" ]; then
  echo "FAIL: tracer-class must be Tracer"
  fail=1
fi
if [ "$(read_key injected-headers)" != "traceparent" ]; then
  echo "FAIL: injected-headers must be traceparent"
  fail=1
fi

sdk_version="$(collector_recent | grep "telemetry.sdk.version" | tail -1 | sed -e 's/.*Str(\(.*\))/\1/')"
if [ -z "$sdk_version" ]; then
  echo "FAIL: the Collector log has no telemetry.sdk.version yet"
  fail=1
elif [ "$(read_key telemetry-sdk-version)" != "$sdk_version" ]; then
  echo "FAIL: telemetry-sdk-version must be $sdk_version, the value in the Collector log"
  fail=1
fi

environment="$(collector_recent | grep "deployment.environment.name" | tail -1 | sed -e 's/.*Str(\(.*\))/\1/')"
if [ -z "$environment" ]; then
  echo "FAIL: the Collector log has no deployment.environment.name yet"
  fail=1
elif [ "$(read_key environment)" != "$environment" ]; then
  echo "FAIL: environment must be $environment, the value in the Collector log"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: composability-evidence matches what the pod and the Collector show"
fi
exit "$fail"
