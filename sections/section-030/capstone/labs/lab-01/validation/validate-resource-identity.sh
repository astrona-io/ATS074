#!/usr/bin/env bash
# Check: fresh telemetry carries the requested resource attributes.
set -uo pipefail

patterns=(
  'service\.name: Str\(shuttle\)'
  'service\.namespace: Str\(starfleet\)'
  'deployment\.environment\.name: Str\(production\)'
  'service\.version: Str\(3\.0\.0\)'
)

for i in $(seq 1 40); do
  log="$(kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null)"
  missing=0
  for pattern in "${patterns[@]}"; do
    echo "$log" | grep -Eq "$pattern" || missing=1
  done
  if [ "$missing" -eq 0 ]; then
    echo "PASS: the resource has the requested name, namespace, environment and version"
    exit 0
  fi
  sleep 3
done
echo "FAIL: fresh telemetry does not carry the requested service.name, service.namespace, deployment.environment.name and service.version"
exit 1
