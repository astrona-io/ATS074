#!/usr/bin/env bash
# Check: workloads are available and the tiers are still wired.
set -uo pipefail

fail=0
for name in gateway shuttle; do
  ready="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica"
    fail=1
  fi
done
agent_ready="$(kubectl -n starfleet get daemonset agent -o jsonpath='{.status.numberReady}' 2>/dev/null || true)"
if [ -z "$agent_ready" ] || [ "$agent_ready" -lt 1 ]; then
  echo "FAIL: daemonset agent has no ready pod"
  fail=1
fi

config="$(kubectl -n starfleet get configmap agent-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if ! echo "$config" | grep -q 'endpoint: gateway:4317'; then
  echo "FAIL: the agent no longer exports to gateway:4317"
  fail=1
fi
gateway_config="$(kubectl -n starfleet get configmap gateway-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if echo "$gateway_config" | grep -qE 'resourcedetection|memory_limiter'; then
  echo "FAIL: gateway-config was changed; the agent must do this work"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: gateway, agent and shuttle are available and wired"
fi
exit "$fail"
