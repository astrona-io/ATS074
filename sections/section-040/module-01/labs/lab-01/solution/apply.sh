#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

# 1. Service identity and the sampler, as environment variables.
kubectl -n starfleet set env deployment/shuttle \
  OTEL_SERVICE_NAME=shuttle \
  OTEL_RESOURCE_ATTRIBUTES=service.version=1.0.0,deployment.environment.name=lab \
  OTEL_TRACES_SAMPLER=parentbased_always_on \
  OTEL_TRACES_SAMPLER_ARG-

# 2. Let the failing report span record its exception and set the error status
# (this is the SDK default, so removing the two arguments is enough).
tmp="$(mktemp)"
kubectl -n starfleet get configmap shuttle-app -o jsonpath='{.data.app\.py}' \
  | sed -e '/record_exception=False,/d' -e '/set_status_on_exception=False,/d' > "$tmp"
kubectl -n starfleet create configmap shuttle-app --from-file=app.py="$tmp" \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f "$tmp"

kubectl -n starfleet rollout restart deployment/shuttle
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[solution] Applied."
