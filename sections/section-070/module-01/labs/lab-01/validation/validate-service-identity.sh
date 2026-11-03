#!/usr/bin/env bash
# Check: the Deployment sets the service identity and fresh telemetry carries it.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deployment scout -o json 2>/dev/null | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}

name="$(env_value OTEL_SERVICE_NAME)"
attrs="$(env_value OTEL_RESOURCE_ATTRIBUTES)"
if [ "$name" != "scout" ]; then
  echo "FAIL: OTEL_SERVICE_NAME is '$name', expected scout"
  exit 1
fi
if ! echo "$attrs" | tr ',' '\n' | grep -qx 'service.namespace=starfleet'; then
  echo "FAIL: OTEL_RESOURCE_ATTRIBUTES must contain service.namespace=starfleet (now '$attrs')"
  exit 1
fi

for i in $(seq 1 30); do
  recent="$(kubectl -n starfleet logs deploy/collector --since=45s 2>/dev/null)"
  if echo "$recent" | grep -q 'service.name: Str(scout)' \
     && echo "$recent" | grep -q 'service.namespace: Str(starfleet)' \
     && ! echo "$recent" | grep -q 'unknown_service'; then
    echo "PASS: fresh telemetry carries service.name scout and service.namespace starfleet"
    exit 0
  fi
  sleep 5
done
echo "FAIL: the last 45 seconds of the Collector log do not show the new service identity"
exit 1
