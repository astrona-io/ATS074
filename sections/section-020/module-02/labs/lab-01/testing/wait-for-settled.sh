#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# Collector shows spans with the custom attribute.
set -euo pipefail

for attempt in $(seq 1 90); do
  seen="$(kubectl -n starfleet logs deploy/collector --since=120s 2>/dev/null | grep -c "starfleet.crew.size" || true)"
  if [ "$seen" -gt 0 ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 2
done
echo "[testing] no span with the custom attribute arrived in time." >&2
exit 1
