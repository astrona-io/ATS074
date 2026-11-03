#!/usr/bin/env bash
# Starting state. Environment only: it creates the Collector and the shuttle
# service with the faults described in question.md. It does not create any
# answer or evidence.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/collector --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[lab] Ready."
