#!/usr/bin/env bash
# Check: the application code and the image were not changed.
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
code="$(kubectl -n "$NS" get configmap shuttle-app -o jsonpath='{.data.app\.py}' 2>/dev/null || true)"
for needle in "def plot_course" "def configure_sdk" 'trace.get_tracer("starfleet.navigation"'; do
  if ! printf '%s' "$code" | grep -qF "$needle"; then
    echo "FAIL: the ConfigMap shuttle-app no longer contains: $needle"
    fail=1
  fi
done
if printf '%s' "$code" | grep -q "ConsoleSpanExporter"; then
  echo "FAIL: the application code was changed to use a console exporter"
  fail=1
fi
image="$(kubectl -n "$NS" get deploy shuttle -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [ "$image" != "python:3.12-slim" ]; then
  echo "FAIL: the shuttle image is '$image', expected python:3.12-slim"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: the application code and the image are unchanged"
fi
exit "$fail"
