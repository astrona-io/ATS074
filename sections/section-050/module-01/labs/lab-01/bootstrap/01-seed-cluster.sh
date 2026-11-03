#!/usr/bin/env bash
# Starting state for the trace pipeline lab. Environment only: it starts the
# Collector and the shuttle service with a trace pipeline that exports no
# spans. It does not apply any fix.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/collector --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
echo "[lab] Ready."
