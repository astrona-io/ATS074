#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# Collector log shows a failed report span from the fixed shuttle.
set -euo pipefail

for i in $(seq 1 60); do
  if kubectl -n starfleet logs deploy/collector --since=60s 2>/dev/null | grep -Eq 'service\.name: Str\(shuttle\)' \
     && kubectl -n starfleet logs deploy/collector --since=60s 2>/dev/null | grep -Eq '\-> Name: exception'; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 5
done
echo "[testing] no fixed telemetry arrived in time." >&2
exit 1
