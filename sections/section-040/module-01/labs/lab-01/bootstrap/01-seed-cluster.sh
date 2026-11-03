#!/usr/bin/env bash
# Starting state for the tracing lab. Environment only: it creates the
# Collector and a shuttle application with three tracing problems. It does
# not fix them.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

# The shuttle runs pip install on start, so allow a long wait.
kubectl -n starfleet rollout status deployment/collector --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[lab] Ready."
