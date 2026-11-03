#!/usr/bin/env bash
# Check: the views are configured and they change what the Collector
# receives: no shuttle.client attribute, no shuttle.fuel.used stream, and the
# duration histogram has the explicit bucket boundaries of the view.
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

views="$(pod_env "$pod" SHUTTLE_VIEWS)"
for wanted in keys buckets drop-fuel; do
  if ! printf '%s' "$views" | tr ',' '\n' | grep -qx "$wanted"; then
    echo "FAIL: SHUTTLE_VIEWS is '$views' and does not contain $wanted"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  deadline=$((SECONDS + 150))
  ok=0
  while [ "$SECONDS" -lt "$deadline" ]; do
    recent="$(kubectl -n starfleet logs deployment/collector --since=30s 2>/dev/null || true)"
    requests="$(printf '%s\n' "$recent" | grep -c 'Name: shuttle\.requests' || true)"
    bounds="$(printf '%s\n' "$recent" | grep -Ec 'ExplicitBounds #[0-9]+: 0\.25' || true)"
    if [ "$requests" -ge 1 ] && [ "$bounds" -ge 1 ]; then
      ok=1
      break
    fi
    sleep 5
  done
  if [ "$ok" -ne 1 ]; then
    echo "FAIL: the Collector log of the last 30 seconds has no shuttle.requests data or no histogram bucket boundary 0.25"
    fail=1
  else
    if printf '%s\n' "$recent" | grep -q 'shuttle\.client'; then
      echo "FAIL: the Collector still receives the attribute shuttle.client"
      fail=1
    fi
    if printf '%s\n' "$recent" | grep -q 'shuttle\.fuel\.used'; then
      echo "FAIL: the Collector still receives the metric shuttle.fuel.used"
      fail=1
    fi
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the views keep shuttle.route only, drop shuttle.fuel.used and set the histogram buckets"
fi
exit "$fail"
