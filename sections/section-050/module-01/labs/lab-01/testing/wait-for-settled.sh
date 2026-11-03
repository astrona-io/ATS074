#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the new
# shuttle pod is ready and has run for a while.
set -euo pipefail

kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
sleep 30
echo "[testing] settled."
