#!/usr/bin/env bash
# Check: deploy/shuttle exports every 10 seconds or faster and asks for delta
# temporality, and the rollout of that change is finished. Reads the live
# Deployment, so it cannot pass before the change.
set -uo pipefail

fail=0

if ! kubectl -n starfleet get deploy shuttle >/dev/null 2>&1; then
  echo "FAIL: deploy/shuttle not found in starfleet"
  exit 1
fi

env_value() {
  kubectl -n starfleet get deploy shuttle \
    -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"$1\")].value}" 2>/dev/null
}

interval="$(env_value OTEL_METRIC_EXPORT_INTERVAL)"
if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1000 ] || [ "$interval" -gt 10000 ]; then
  echo "FAIL: OTEL_METRIC_EXPORT_INTERVAL is '$interval', expected a number of milliseconds from 1000 to 10000"
  fail=1
fi

temporality="$(env_value OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE | tr '[:upper:]' '[:lower:]')"
if [ "$temporality" != "delta" ]; then
  echo "FAIL: OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE is '$temporality', expected delta"
  fail=1
fi

generation="$(kubectl -n starfleet get deploy shuttle -o jsonpath='{.metadata.generation}')"
observed="$(kubectl -n starfleet get deploy shuttle -o jsonpath='{.status.observedGeneration}')"
available="$(kubectl -n starfleet get deploy shuttle -o jsonpath='{.status.availableReplicas}')"
updated="$(kubectl -n starfleet get deploy shuttle -o jsonpath='{.status.updatedReplicas}')"
if [ "$generation" != "$observed" ] || [ "${available:-0}" != "1" ] || [ "${updated:-0}" != "1" ]; then
  echo "FAIL: the rollout of deploy/shuttle is not finished (generation=$generation observed=$observed updated=${updated:-0} available=${available:-0})"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle exports every ${interval} ms with delta temporality"
fi
exit "$fail"
