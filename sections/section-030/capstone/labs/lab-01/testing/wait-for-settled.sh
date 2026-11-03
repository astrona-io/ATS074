#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the new
# shuttle pod exports spans and metrics to the collector.
set -euo pipefail

for i in $(seq 1 60); do
  log="$(kubectl -n starfleet logs deploy/collector --since=20s 2>/dev/null || true)"
  if echo "$log" | grep -Eq 'Name +: dock' && echo "$log" | grep -Eq 'Name: +shuttle\.docks' && echo "$log" | grep -Eq 'service.version: Str\(3.0.0\)'; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 3
done
echo "[testing] no fresh telemetry from the new pod." >&2
exit 1
