#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits for the shuttle
# rollout. The validation scripts poll the Collector log themselves.
set -euo pipefail

kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[testing] settled."
