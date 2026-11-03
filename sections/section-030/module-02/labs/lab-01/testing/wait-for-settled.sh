#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the new
# shuttle pod exports metrics to the collector.
set -euo pipefail

for i in $(seq 1 60); do
  if kubectl -n starfleet logs deploy/collector --since=20s 2>/dev/null | grep -Eq 'Name: +shuttle\.docks'; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 3
done
echo "[testing] no fresh metrics from the new pod." >&2
exit 1
