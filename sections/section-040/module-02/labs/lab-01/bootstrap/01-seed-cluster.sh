#!/usr/bin/env bash
# Starting state for the metrics lab. Environment only: it creates the
# `starfleet` namespace, the Collector and the shuttle program with a 60 second
# interval, cumulative temporality and an empty views file. The fix is the
# learner's work.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/collector --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[lab] Ready."
