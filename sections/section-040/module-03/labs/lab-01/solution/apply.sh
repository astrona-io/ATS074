#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deployment/shuttle \
  OTEL_SERVICE_NAME=shuttle \
  OTEL_RESOURCE_ATTRIBUTES=service.version=1.4.0,deployment.environment.name=training \
  SHUTTLE_LOG_LEVEL=INFO \
  SHUTTLE_LOG_PAYLOAD=false \
  SHUTTLE_LOG_INSIDE_SPAN=true

kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[solution] Applied."
