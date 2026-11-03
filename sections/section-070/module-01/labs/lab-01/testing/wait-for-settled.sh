#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# Collector log has fresh scout spans.
set -euo pipefail

for i in $(seq 1 60); do
  if kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null | grep -q 'service.name: Str(scout)'; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 5
done
echo "[testing] no fresh scout telemetry in time." >&2
exit 1
