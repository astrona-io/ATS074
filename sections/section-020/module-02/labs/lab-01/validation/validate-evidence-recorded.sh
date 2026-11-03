#!/usr/bin/env bash
# Check: the ConfigMap pipeline-evidence matches the pod log, the endpoint and the Collector log.
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
  kubectl -n "$NS" get configmap pipeline-evidence -o json 2>/dev/null | jq -r --arg key "$1" '.data[$key] // empty'
}

if ! kubectl -n "$NS" get configmap pipeline-evidence >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap pipeline-evidence does not exist in $NS"
  exit 1
fi

if [ "$(read_key processors)" != "crew-tag,batch" ]; then
  echo "FAIL: processors must be crew-tag,batch"
  fail=1
fi

endpoint="$(deploy_env OTEL_EXPORTER_OTLP_ENDPOINT)"
port="${endpoint%/}"
port="${port##*:}"
if [ "$(read_key exporter-port)" != "$port" ]; then
  echo "FAIL: exporter-port must be $port, the port in the endpoint"
  fail=1
fi

crew="$(collector_recent | grep "starfleet.crew.size" | tail -1 | sed -e 's/.*Int(\(.*\))/\1/')"
if [ -z "$crew" ]; then
  echo "FAIL: the Collector log has no starfleet.crew.size yet"
  fail=1
elif [ "$(read_key crew-size)" != "$crew" ]; then
  echo "FAIL: crew-size must be $crew, the value in the Collector log"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: pipeline-evidence matches what the pod and the Collector show"
fi
exit "$fail"
