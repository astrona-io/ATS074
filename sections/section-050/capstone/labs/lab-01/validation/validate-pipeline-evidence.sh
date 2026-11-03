#!/usr/bin/env bash
# Check: the evidence record. The ConfigMap pipeline-evidence must repeat the
# configuration the running pod really uses, so a copied or invented record
# fails when the pipeline differs.
set -uo pipefail

# Shared snippet copied into each validation script (labs are self-contained).
current_pod() {
  kubectl -n starfleet get pods -l app=shuttle -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | sort_by(.metadata.creationTimestamp) | last | .metadata.name // empty'
}
pod_env() {
  kubectl -n starfleet get pod "$1" -o json | jq -r --arg name "$2" '[.spec.containers[0].env[]? | select(.name == $name) | .value // ""] | first // ""'
}
wait_for_ready_pod() {
  local deadline=$((SECONDS + 240)) name ready
  while [ "$SECONDS" -lt "$deadline" ]; do
    name="$(current_pod)"
    if [ -n "$name" ]; then
      ready="$(kubectl -n starfleet get pod "$name" -o json | jq -r '[.status.conditions[]? | select(.type == "Ready") | .status] | first // "False"')"
      if [ "$ready" = "True" ]; then
        echo "$name"
        return 0
      fi
    fi
    sleep 5
  done
  return 1
}

fail=0
NS=starfleet
NAME=pipeline-evidence

if ! kubectl -n "$NS" get configmap "$NAME" >/dev/null 2>&1; then
  echo "FAIL: ConfigMap $NAME not found in $NS"
  exit 1
fi
pod="$(wait_for_ready_pod)" || { echo "FAIL: no ready shuttle pod after 4 minutes"; exit 1; }

read_key() {
  kubectl -n "$NS" get configmap "$NAME" -o json | jq -r --arg key "$1" '.data[$key] // ""'
}

compare() {
  local key="$1" variable="$2" recorded live
  recorded="$(read_key "$key")"
  live="$(pod_env "$pod" "$variable")"
  if [ -z "$recorded" ] || [ "$recorded" != "$live" ]; then
    echo "FAIL: key '$key' is '$recorded', the running pod has $variable='$live'"
    fail=1
  fi
}

compare endpoint OTEL_EXPORTER_OTLP_ENDPOINT
compare sampler OTEL_TRACES_SAMPLER
compare sampler-arg OTEL_TRACES_SAMPLER_ARG
compare metric-export-interval-ms OTEL_METRIC_EXPORT_INTERVAL

observed="$(read_key observed-at)"
if ! printf '%s' "$observed" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
  echo "FAIL: key 'observed-at' must be a UTC time like 2026-11-03T10:15:00Z"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the evidence record matches the configuration of the running pod"
fi
exit "$fail"
