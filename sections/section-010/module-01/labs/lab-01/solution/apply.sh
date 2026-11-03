#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deployment/shuttle \
  OTEL_SERVICE_NAME=shuttle \
  "OTEL_RESOURCE_ATTRIBUTES=service.namespace=starfleet,service.version=1.0.0,deployment.environment.name=training"
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[solution] Applied."
