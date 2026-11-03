#!/usr/bin/env bash
# Check: fresh scout spans at the gateway are enriched by the agent and have
# no health check spans.
set -uo pipefail

for i in $(seq 1 30); do
  recent="$(kubectl -n starfleet logs deploy/gateway --since=40s 2>/dev/null)"
  if echo "$recent" | grep -q 'service.name: Str(scout)' \
     && echo "$recent" | grep -qE 'Name +: GET /(relay|dock)' \
     && echo "$recent" | grep -q 'host.name: Str(' \
     && echo "$recent" | grep -q 'deployment.environment.name: Str(starfleet-lab)' \
     && ! echo "$recent" | grep -q 'GET /healthz'; then
    echo "PASS: enriched scout server spans arrive at the gateway without health check spans"
    exit 0
  fi
  sleep 5
done
echo "FAIL: the last 40 seconds of the gateway log do not show enriched scout spans without /healthz"
exit 1
