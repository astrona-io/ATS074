#!/usr/bin/env bash
# Starting state for the instrumentation agent lab. Environment only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

for name in collector scout drifter; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=420s
done
echo "[lab] Ready."
