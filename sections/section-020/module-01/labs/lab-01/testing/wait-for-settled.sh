#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the new
# pod prints a real tracer and the Collector has received its data.
set -euo pipefail

for attempt in $(seq 1 90); do
  line="$(kubectl -n starfleet logs deploy/shuttle 2>/dev/null | grep "pipeline:" | tail -1 || true)"
  seen="$(kubectl -n starfleet logs deploy/collector --since=120s 2>/dev/null | grep -c "service.name: Str(shuttle)" || true)"
  if echo "$line" | grep -q "tracer=Tracer " && [ "$seen" -gt 0 ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 2
done
echo "[testing] the service did not export telemetry in time." >&2
exit 1
