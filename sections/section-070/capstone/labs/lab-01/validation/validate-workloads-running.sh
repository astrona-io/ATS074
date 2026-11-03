#!/usr/bin/env bash
# Check: workloads are available and scout is still zero-code.
set -uo pipefail

fail=0
for name in gateway scout drifter; do
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

image="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [ "$image" != "python:3.12-slim" ]; then
  echo "FAIL: scout runs image '$image', expected python:3.12-slim"
  fail=1
fi
start="$(kubectl -n starfleet get configmap scout-app -o jsonpath='{.data.start\.sh}' 2>/dev/null || true)"
if ! echo "$start" | grep -q 'opentelemetry-instrument'; then
  echo "FAIL: start.sh no longer runs opentelemetry-instrument"
  fail=1
fi
app="$(kubectl -n starfleet get configmap scout-app -o jsonpath='{.data.app\.py}' 2>/dev/null || true)"
if echo "$app" | grep -qi 'opentelemetry'; then
  echo "FAIL: app.py contains OpenTelemetry code"
  fail=1
fi
gateway_config="$(kubectl -n starfleet get configmap gateway-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if echo "$gateway_config" | grep -qE 'resourcedetection|memory_limiter'; then
  echo "FAIL: gateway-config was changed; the agent must do this work"
  fail=1
fi
agent_config="$(kubectl -n starfleet get configmap agent-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if ! echo "$agent_config" | grep -q 'endpoint: gateway:4317'; then
  echo "FAIL: the agent no longer exports to gateway:4317"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: workloads are available and scout is still zero-code"
fi
exit "$fail"
