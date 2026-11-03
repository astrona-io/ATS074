#!/usr/bin/env bash
# Check: the OTLP headers come from the Secret and no token is in the Deployment.
set -uo pipefail

deploy_json="$(kubectl -n starfleet get deploy shuttle -o json)"
entry="$(echo "$deploy_json" | jq '.spec.template.spec.containers[0].env[]? | select(.name == "OTEL_EXPORTER_OTLP_HEADERS")')"

if [ -z "$entry" ]; then
  echo "FAIL: OTEL_EXPORTER_OTLP_HEADERS is not set on the Deployment"
  exit 1
fi
secret_name="$(echo "$entry" | jq -r '.valueFrom.secretKeyRef.name // empty')"
secret_key="$(echo "$entry" | jq -r '.valueFrom.secretKeyRef.key // empty')"
if [ "$secret_name" != "collector-auth" ] || [ "$secret_key" != "otlp-headers" ]; then
  echo "FAIL: OTEL_EXPORTER_OTLP_HEADERS must use secretKeyRef collector-auth / otlp-headers"
  exit 1
fi
if echo "$deploy_json" | grep -q 'hailing-frequency-7'; then
  echo "FAIL: the token is still written as plain text in the Deployment"
  exit 1
fi
token="$(kubectl -n starfleet get secret collector-auth -o json 2>/dev/null | jq -r '.data["otlp-headers"] // empty' | base64 --decode 2>/dev/null)"
if [ "$token" != "x-starfleet-token=hailing-frequency-7" ]; then
  echo "FAIL: the Secret collector-auth must hold otlp-headers=x-starfleet-token=hailing-frequency-7"
  exit 1
fi
echo "PASS: the headers come from the Secret and no token is in the Deployment"
