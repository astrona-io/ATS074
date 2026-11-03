#!/usr/bin/env bash
# Check: the running shuttle pod uses the batching span processor with a
# queue of at least 4096 spans, batches of at most 256 and a schedule delay
# of at most 2000 milliseconds.
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

processor="$(pod_env "$pod" SHUTTLE_SPAN_PROCESSOR)"
queue="$(pod_env "$pod" OTEL_BSP_MAX_QUEUE_SIZE)"
batch="$(pod_env "$pod" OTEL_BSP_MAX_EXPORT_BATCH_SIZE)"
delay="$(pod_env "$pod" OTEL_BSP_SCHEDULE_DELAY)"

if [ "$processor" != "batch" ]; then
  echo "FAIL: SHUTTLE_SPAN_PROCESSOR is '$processor', expected batch"
  fail=1
fi
case "$queue" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BSP_MAX_QUEUE_SIZE must be a number, found '$queue'"; fail=1 ;;
  *) [ "$queue" -ge 4096 ] || { echo "FAIL: OTEL_BSP_MAX_QUEUE_SIZE is $queue, expected at least 4096"; fail=1; } ;;
esac
case "$batch" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BSP_MAX_EXPORT_BATCH_SIZE must be a number, found '$batch'"; fail=1 ;;
  *) { [ "$batch" -ge 1 ] && [ "$batch" -le 256 ]; } || { echo "FAIL: OTEL_BSP_MAX_EXPORT_BATCH_SIZE is $batch, expected 1 to 256"; fail=1; } ;;
esac
case "$delay" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BSP_SCHEDULE_DELAY must be a number of milliseconds, found '$delay'"; fail=1 ;;
  *) { [ "$delay" -ge 100 ] && [ "$delay" -le 2000 ]; } || { echo "FAIL: OTEL_BSP_SCHEDULE_DELAY is $delay, expected 100 to 2000"; fail=1; } ;;
esac
if ! kubectl -n starfleet logs "$pod" 2>/dev/null | grep -q 'span_processor=batch '; then
  echo "FAIL: the shuttle log line '[shuttle] config' does not show span_processor=batch"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle uses the batching span processor with a 4096 queue"
fi
exit "$fail"
