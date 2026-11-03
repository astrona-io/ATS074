#!/usr/bin/env bash
# Starting state for the agent and gateway lab. Environment only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n starfleet rollout status deployment/gateway --timeout=300s
kubectl -n starfleet rollout status daemonset/agent --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=420s
echo "[lab] Ready."
