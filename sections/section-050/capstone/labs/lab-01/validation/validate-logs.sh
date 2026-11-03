#!/usr/bin/env bash
# Check: the running shuttle pod has a log record queue of at least 2048
# records and a batch size between 1 and 512, and the Collector receives log
# records that carry a trace ID.
set -uo pipefail

# Shared snippet copied into each validation script (labs are self-contained).
current_pod() {
  kubectl -n starfleet get pods -l app=shuttle -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | sort_by(.metadata.creationTimestamp) | last | .metadata.name // empty'
}
pod_env() {
  kubectl -n starfleet get pod "$1" -o json | jq -r --arg name "$2" '[.spec.containers[0].env[]? | select(.name == $name) | .value // ""] | first // ""'
}
wait_for_ready_pod() {
  local deadline=$((SECONDS + 240)) name ready
  while [ "$SECONDS" -lt "$deadline" ]; do
    name="$(current_pod)"
    if [ -n "$name" ]; then
      ready="$(kubectl -n starfleet get pod "$name" -o json | jq -r '[.status.conditions[]? | select(.type == "Ready") | .status] | first // "False"')"
      if [ "$ready" = "True" ]; then
        echo "$name"
        return 0
      fi
    fi
    sleep 5
  done
  return 1
}

fail=0
pod="$(wait_for_ready_pod)" || { echo "FAIL: no ready shuttle pod after 4 minutes"; exit 1; }

queue="$(pod_env "$pod" OTEL_BLRP_MAX_QUEUE_SIZE)"
batch="$(pod_env "$pod" OTEL_BLRP_MAX_EXPORT_BATCH_SIZE)"
case "$queue" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BLRP_MAX_QUEUE_SIZE must be a number, found '$queue'"; fail=1 ;;
  *) [ "$queue" -ge 2048 ] || { echo "FAIL: OTEL_BLRP_MAX_QUEUE_SIZE is $queue, expected at least 2048"; fail=1; } ;;
esac
case "$batch" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BLRP_MAX_EXPORT_BATCH_SIZE must be a number, found '$batch'"; fail=1 ;;
  *) { [ "$batch" -ge 1 ] && [ "$batch" -le 512 ]; } || { echo "FAIL: OTEL_BLRP_MAX_EXPORT_BATCH_SIZE is $batch, expected 1 to 512"; fail=1; } ;;
esac

if [ "$fail" -eq 0 ]; then
  deadline=$((SECONDS + 150))
  seen=0
  while [ "$SECONDS" -lt "$deadline" ]; do
    recent="$(kubectl -n starfleet logs deployment/collector --since=45s 2>/dev/null || true)"
    from_pod="$(printf '%s\n' "$recent" | grep -c "service.instance.id: Str($pod)" || true)"
    traced="$(printf '%s\n' "$recent" | grep -Ec 'Trace ID: +[0-9a-f]{32}' || true)"
    if [ "$from_pod" -ge 1 ] && [ "$traced" -ge 1 ]; then
      seen=1
      break
    fi
    sleep 5
  done
  if [ "$seen" -ne 1 ]; then
    echo "FAIL: the Collector log of the last 45 seconds has no log record from $pod with a trace ID"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle batches log records with a $queue record queue and the Collector receives them with trace IDs"
fi
exit "$fail"
