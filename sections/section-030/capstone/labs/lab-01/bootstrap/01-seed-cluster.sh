#!/usr/bin/env bash
# Starting state for the lab. Environment only: the namespace, the collector and
# the misconfigured shuttle service. Fixing the configuration is the learner's work.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deploy/collector --timeout=300s
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
echo "[lab] Ready."
