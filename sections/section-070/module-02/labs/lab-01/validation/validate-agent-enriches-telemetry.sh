#!/usr/bin/env bash
# Check: fresh spans at the gateway carry attributes only the agent can add.
set -uo pipefail

for i in $(seq 1 30); do
  recent="$(kubectl -n starfleet logs deploy/gateway --since=45s 2>/dev/null)"
  if echo "$recent" | grep -q 'service.name: Str(shuttle)' \
     && echo "$recent" | grep -q 'host.name: Str(' \
     && echo "$recent" | grep -q 'deployment.environment.name: Str(starfleet-lab)'; then
    echo "PASS: shuttle telemetry at the gateway carries host.name and deployment.environment.name"
    exit 0
  fi
  sleep 5
done
echo "FAIL: the last 45 seconds of the gateway log have no shuttle telemetry with host.name and deployment.environment.name"
exit 1
