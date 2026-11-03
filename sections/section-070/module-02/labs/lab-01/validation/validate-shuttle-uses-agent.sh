#!/usr/bin/env bash
# Check: shuttle exports to the agent Service.
set -uo pipefail

endpoint="$(kubectl -n starfleet get deployment shuttle -o json 2>/dev/null | jq -r '[.spec.template.spec.containers[0].env[]? | select(.name=="OTEL_EXPORTER_OTLP_ENDPOINT") | .value] | first // ""')"
case "$endpoint" in
  http://agent:4318*|http://agent.starfleet:4318*|http://agent.starfleet.svc:4318*|http://agent.starfleet.svc.cluster.local:4318*)
    echo "PASS: shuttle sends OTLP to the agent ($endpoint)"
    exit 0
    ;;
esac
echo "FAIL: OTEL_EXPORTER_OTLP_ENDPOINT is '$endpoint', expected http://agent:4318"
exit 1
