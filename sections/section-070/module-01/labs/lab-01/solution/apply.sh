#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deployment/scout \
  OTEL_PYTHON_DISABLED_INSTRUMENTATIONS- \
  OTEL_SERVICE_NAME=scout \
  OTEL_RESOURCE_ATTRIBUTES=service.namespace=starfleet \
  OTEL_PYTHON_EXCLUDED_URLS=healthz

kubectl -n starfleet rollout status deployment/scout --timeout=420s
echo "[solution] Applied."
