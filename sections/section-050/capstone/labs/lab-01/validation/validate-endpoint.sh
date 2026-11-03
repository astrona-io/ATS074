#!/usr/bin/env bash
# Check: the running shuttle pod sends OTLP/HTTP to port 4318 of the collector
# Service. The pod log must not show an export failure from the last minute.
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
pod="$(wait_for_ready_pod)" || { echo "FAIL: no ready shuttle pod after 4 minutes"; exit 1; }

endpoint="$(pod_env "$pod" OTEL_EXPORTER_OTLP_ENDPOINT)"
if ! printf '%s' "$endpoint" | grep -Eq '^http://collector(\.starfleet(\.svc(\.cluster\.local)?)?)?:4318/?$'; then
  echo "FAIL: OTEL_EXPORTER_OTLP_ENDPOINT is '$endpoint'; the OTLP/HTTP receiver of the collector Service listens on port 4318"
  fail=1
fi

sleep 20
if kubectl -n starfleet logs "$pod" --since=60s 2>/dev/null | grep -Eqi 'failed to export|connection refused|max retries'; then
  echo "FAIL: the shuttle log of the last minute still shows export failures"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle exports to the collector OTLP/HTTP port without errors"
fi
exit "$fail"
