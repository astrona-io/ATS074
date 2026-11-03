#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deploy/shuttle \
  OTEL_SDK_DISABLED- \
  OTEL_SERVICE_NAME=shuttle \
  OTEL_RESOURCE_ATTRIBUTES="service.namespace=starfleet,deployment.environment.name=production,service.version=2.4.1"
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
echo "[solution] Applied."
