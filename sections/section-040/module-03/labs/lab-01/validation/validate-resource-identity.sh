#!/usr/bin/env bash
# Check: the Resource of the shuttle names the service and the environment, and
# the collector receives log records that carry both.
set -uo pipefail

NS=starfleet
# The shuttle needs a minute to install the SDK after every change, so every
# check polls (up to about 150 seconds) for fresh records in the collector log.
fresh_logs() { kubectl -n "$NS" logs deploy/collector --since="${1:-20}s" 2>/dev/null; }
wait_until() {
  local check="$1" i
  for i in $(seq 1 50); do
    if "$check"; then return 0; fi
    sleep 3
  done
  return 1
}

env_value() {
  kubectl -n "$NS" get deployment shuttle -o json | jq -r --arg name "$1" '.spec.template.spec.containers[0].env[]? | select(.name == $name) | .value' | head -n 1
}

fail=0
service="$(env_value OTEL_SERVICE_NAME)"
if [ "$service" != "shuttle" ]; then
  echo "FAIL: OTEL_SERVICE_NAME is '$service', expected 'shuttle'"
  fail=1
fi
attributes="$(env_value OTEL_RESOURCE_ATTRIBUTES)"
if ! echo "$attributes" | grep -q 'deployment.environment.name=training'; then
  echo "FAIL: OTEL_RESOURCE_ATTRIBUTES must contain deployment.environment.name=training (found '$attributes')"
  fail=1
fi
[ "$fail" -ne 0 ] && exit 1

resource_in_logs() {
  local text
  text="$(fresh_logs 20)"
  echo "$text" | grep -q 'LogRecord #' || return 1
  echo "$text" | grep -q 'service.name: Str(shuttle)' || return 1
  echo "$text" | grep -q 'deployment.environment.name: Str(training)' || return 1
  ! echo "$text" | grep -q 'service.name: Str(unknown_service'
}

if wait_until resource_in_logs; then
  echo "PASS: fresh log records carry service.name shuttle and deployment.environment.name training"
  exit 0
fi
echo "FAIL: no fresh log record with service.name shuttle and deployment.environment.name training reached the collector"
exit 1
