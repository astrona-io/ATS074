#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the old
# shuttle pod is gone.
set -euo pipefail

for i in $(seq 1 60); do
  pods="$(kubectl -n starfleet get pods -l app=shuttle -o json | jq '.items | length')"
  if [ "$pods" = "1" ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 2
done
echo "[testing] the old shuttle pod did not terminate in time." >&2
exit 1
