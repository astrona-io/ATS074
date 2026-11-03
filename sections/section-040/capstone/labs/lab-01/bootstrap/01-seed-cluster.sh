#!/usr/bin/env bash
# Starting state for the capstone lab. Environment only: it creates the
# collector and the shuttle with failing settings for all three signals. The
# shuttle installs the SDK with pip when it starts, so the timeouts are long.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n starfleet rollout status deployment/collector --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[lab] Ready."
