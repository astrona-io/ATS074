#!/usr/bin/env bash
# Check: the agent pod template asks for no host access.
set -uo pipefail

spec="$(kubectl -n starfleet get daemonset agent -o json 2>/dev/null | jq '.spec.template.spec' 2>/dev/null)"
if [ -z "$spec" ] || [ "$spec" = "null" ]; then
  echo "FAIL: daemonset agent not found"
  exit 1
fi

fail=0
hostpaths="$(echo "$spec" | jq -r '[.volumes[]? | select(.hostPath != null) | .hostPath.path] | join(",")')"
if [ -n "$hostpaths" ]; then
  echo "FAIL: the agent still has hostPath volumes: $hostpaths"
  fail=1
fi
privileged="$(echo "$spec" | jq '[.containers[]? | select(.securityContext.privileged == true)] | length')"
if [ "$privileged" != "0" ]; then
  echo "FAIL: the agent has a privileged container"
  fail=1
fi
hostnet="$(echo "$spec" | jq -r '.hostNetwork // false')"
if [ "$hostnet" = "true" ]; then
  echo "FAIL: the agent uses hostNetwork"
  fail=1
fi
dangling="$(echo "$spec" | jq -r '[.volumes[]?.name] as $v | [.containers[]?.volumeMounts[]? | select(.name as $n | ($v | index($n)) == null) | .name] | join(",")')"
if [ -n "$dangling" ]; then
  echo "FAIL: volumeMounts without a volume: $dangling"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the agent pod asks for no host files, no privilege and no host network"
fi
exit "$fail"
