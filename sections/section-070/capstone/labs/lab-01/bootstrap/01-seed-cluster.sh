#!/usr/bin/env bash
# Starting state for the agents capstone. Environment only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

kubectl -n starfleet rollout status deployment/gateway --timeout=300s
kubectl -n starfleet rollout status daemonset/agent --timeout=300s
for name in scout drifter; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=420s
done
echo "[lab] Ready."
