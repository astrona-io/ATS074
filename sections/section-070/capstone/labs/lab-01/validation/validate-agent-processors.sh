#!/usr/bin/env bash
# Check: the agent config has the three processors in the right order.
set -uo pipefail

config="$(kubectl -n starfleet get configmap agent-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"
if [ -z "$config" ]; then
  echo "FAIL: ConfigMap agent-config has no config.yaml"
  exit 1
fi

fail=0
for name in memory_limiter resourcedetection batch; do
  if ! echo "$config" | grep -qE "^  ${name}:"; then
    echo "FAIL: processor $name is not defined under processors"
    fail=1
  fi
done
if ! echo "$config" | grep -qE '^ +limit_(mib|percentage):'; then
  echo "FAIL: memory_limiter needs limit_mib or limit_percentage"
  fail=1
fi
detectors="$(echo "$config" | grep -E '^ +detectors:' | head -n 1)"
for d in env system; do
  if ! echo "$detectors" | grep -qE "\b${d}\b"; then
    echo "FAIL: resourcedetection detectors must include $d (now: ${detectors:-none})"
    fail=1
  fi
done

service="$(echo "$config" | sed -n '/^service:/,$p')"
pipeline_lines="$(echo "$service" | grep -E '^ +processors:')"
count="$(echo "$pipeline_lines" | grep -c . || true)"
if [ "$count" -lt 2 ]; then
  echo "FAIL: expected a processors line in the traces and in the metrics pipeline (found $count)"
  fail=1
fi
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if ! echo "$line" | grep -qE '\[ *memory_limiter *, *resourcedetection *, *batch *\]'; then
    echo "FAIL: pipeline processors must be [memory_limiter, resourcedetection, batch], found: $line"
    fail=1
  fi
done <<< "$pipeline_lines"

if [ "$fail" -eq 0 ]; then
  echo "PASS: agent-config defines and orders memory_limiter, resourcedetection and batch"
fi
exit "$fail"
