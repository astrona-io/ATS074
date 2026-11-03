#!/usr/bin/env bash
# Starting state. Environment only: it creates the collector, the probe and the
# shuttle. It does not create the evidence ConfigMaps the learner must write.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/starfleet.yaml"

for name in collector probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=300s
done
echo "[lab] Ready."
