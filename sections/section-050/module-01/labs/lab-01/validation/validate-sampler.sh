#!/usr/bin/env bash
# Check: the running shuttle pod uses the parent-based trace ID ratio sampler
# with a ratio of 0.5, and the SDK reported it at start.
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

sampler="$(pod_env "$pod" OTEL_TRACES_SAMPLER)"
arg="$(pod_env "$pod" OTEL_TRACES_SAMPLER_ARG)"
if [ "$sampler" != "parentbased_traceidratio" ]; then
  echo "FAIL: OTEL_TRACES_SAMPLER is '$sampler', expected parentbased_traceidratio"
  fail=1
fi
if ! awk -v value="$arg" 'BEGIN { exit !(value != "" && value + 0 == 0.5) }'; then
  echo "FAIL: OTEL_TRACES_SAMPLER_ARG is '$arg', expected 0.5"
  fail=1
fi
if ! kubectl -n starfleet logs "$pod" 2>/dev/null | grep -q 'sampler=parentbased_traceidratio sampler_arg=0.5 '; then
  echo "FAIL: the shuttle log line '[shuttle] config' does not show the new sampler"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle samples with parentbased_traceidratio at 0.5"
fi
exit "$fail"
