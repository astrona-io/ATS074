#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution.
set -euo pipefail

for i in $(seq 1 60); do
  recent="$(kubectl -n starfleet logs deploy/gateway --since=30s 2>/dev/null || true)"
  if echo "$recent" | grep -q 'service.name: Str(scout)' && echo "$recent" | grep -q 'deployment.environment.name: Str(starfleet-lab)'; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 5
done
echo "[testing] no enriched scout telemetry at the gateway in time." >&2
exit 1
