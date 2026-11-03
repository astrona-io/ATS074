#!/usr/bin/env bash
# Check: the exporter endpoint uses port 4318 and metrics reach the Collector.
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

endpoint="$(deploy_env OTEL_EXPORTER_OTLP_ENDPOINT)"
case "${endpoint%/}" in
  *:4318) ;;
  *)
    echo "FAIL: the endpoint '$endpoint' does not use the Collector HTTP port 4318"
    exit 1
    ;;
esac

metrics_arrive() {
  collector_recent | grep -q "shuttle.jumps"
}

if wait_until metrics_arrive; then
  echo "PASS: the endpoint uses port 4318 and the metric shuttle.jumps arrives"
  exit 0
fi
echo "FAIL: recent Collector output has no shuttle.jumps metric"
exit 1
