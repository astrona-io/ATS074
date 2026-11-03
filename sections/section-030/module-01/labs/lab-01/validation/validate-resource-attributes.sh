#!/usr/bin/env bash
# Check: the fresh resource carries the three requested attributes.
set -uo pipefail

patterns=(
  'service\.namespace: Str\(starfleet\)'
  'deployment\.environment\.name: Str\(production\)'
  'service\.version: Str\(2\.4\.1\)'
)

for i in $(seq 1 40); do
  log="$(kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null)"
  missing=0
  for pattern in "${patterns[@]}"; do
    echo "$log" | grep -Eq "$pattern" || missing=1
  done
  if [ "$missing" -eq 0 ]; then
    echo "PASS: the resource has the requested namespace, environment and version"
    exit 0
  fi
  sleep 3
done
echo "FAIL: fresh telemetry does not carry service.namespace=starfleet, deployment.environment.name=production and service.version=2.4.1"
exit 1
