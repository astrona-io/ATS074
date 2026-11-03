#!/usr/bin/env bash
# Check: the running shuttle pod flushes and shuts down the providers on
# SIGTERM, and Kubernetes gives it enough time to finish.
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

on_term="$(pod_env "$pod" SHUTTLE_ON_TERM)"
if [ "$on_term" != "shutdown" ]; then
  echo "FAIL: SHUTTLE_ON_TERM is '$on_term', expected shutdown"
  fail=1
fi

grace="$(kubectl -n starfleet get pod "$pod" -o jsonpath='{.spec.terminationGracePeriodSeconds}')"
if [ -z "$grace" ] || [ "$grace" -lt 30 ]; then
  echo "FAIL: terminationGracePeriodSeconds is '$grace', the shutdown needs at least 30 seconds"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle shuts down its providers on SIGTERM and has a 30 second grace period"
fi
exit "$fail"
