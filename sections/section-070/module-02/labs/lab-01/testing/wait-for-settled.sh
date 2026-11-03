#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# gateway log has spans enriched by the agent.
set -euo pipefail

for i in $(seq 1 60); do
  if kubectl -n starfleet logs deploy/gateway --since=30s 2>/dev/null | grep -q 'deployment.environment.name: Str(starfleet-lab)'; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 5
done
echo "[testing] no enriched telemetry at the gateway in time." >&2
exit 1
