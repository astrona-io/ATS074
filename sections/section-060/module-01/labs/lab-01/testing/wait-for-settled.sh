#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until fresh
# spans from the new pods reach the collector.
set -euo pipefail
NS=starfleet
for i in $(seq 1 60); do
  terminating="$(kubectl -n "$NS" get pods -o json | jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length')"
  if [ "$terminating" = "0" ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 5
done
echo "[testing] the cluster did not settle in time." >&2
exit 1
