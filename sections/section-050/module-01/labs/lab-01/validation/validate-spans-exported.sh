#!/usr/bin/env bash
# Check: the Collector received spans from the current shuttle pod in the
# last minute. The check waits up to about 2.5 minutes for fresh spans.
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

pod="$(wait_for_ready_pod)" || { echo "FAIL: no ready shuttle pod after 4 minutes"; exit 1; }

deadline=$((SECONDS + 150))
while [ "$SECONDS" -lt "$deadline" ]; do
  recent="$(kubectl -n starfleet logs deployment/collector --since=45s 2>/dev/null || true)"
  from_pod="$(printf '%s\n' "$recent" | grep -c "service.instance.id: Str($pod)" || true)"
  span_names="$(printf '%s\n' "$recent" | grep -Ec 'Name +: shuttle\.(dock|launch|scan)$' || true)"
  if [ "$from_pod" -ge 1 ] && [ "$span_names" -ge 1 ]; then
    echo "PASS: the Collector received spans from $pod"
    exit 0
  fi
  sleep 5
done
echo "FAIL: the Collector log of the last 45 seconds has no shuttle.dock, shuttle.launch or shuttle.scan span from $pod"
exit 1
