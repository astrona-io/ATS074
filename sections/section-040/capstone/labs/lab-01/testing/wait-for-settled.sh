#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the old
# shuttle pod is gone and the new one is ready.
set -euo pipefail

for i in $(seq 1 60); do
  terminating="$(kubectl -n starfleet get pods -l app=shuttle -o json | jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length')"
  ready="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.status.availableReplicas}')"
  if [ "$terminating" = "0" ] && [ "${ready:-0}" -ge 1 ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 3
done
echo "[testing] the shuttle did not settle in time." >&2
exit 1
