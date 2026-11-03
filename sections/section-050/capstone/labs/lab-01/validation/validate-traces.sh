#!/usr/bin/env bash
# Check: the trace pipeline. Parent-based ratio sampler between 0.1 and 0.5,
# batching span processor with a queue of at least 2048, batches of at most
# 512, schedule delay of at most 5000 ms, and spans reach the Collector.
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

sampler="$(pod_env "$pod" OTEL_TRACES_SAMPLER)"
arg="$(pod_env "$pod" OTEL_TRACES_SAMPLER_ARG)"
if [ "$sampler" != "parentbased_traceidratio" ]; then
  echo "FAIL: OTEL_TRACES_SAMPLER is '$sampler', expected parentbased_traceidratio"
  fail=1
fi
if ! awk -v value="$arg" 'BEGIN { exit !(value != "" && value + 0 >= 0.1 && value + 0 <= 0.5) }'; then
  echo "FAIL: OTEL_TRACES_SAMPLER_ARG is '$arg', expected a ratio from 0.1 to 0.5"
  fail=1
fi

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
  *) [ "$queue" -ge 2048 ] || { echo "FAIL: OTEL_BSP_MAX_QUEUE_SIZE is $queue, expected at least 2048"; fail=1; } ;;
esac
case "$batch" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BSP_MAX_EXPORT_BATCH_SIZE must be a number, found '$batch'"; fail=1 ;;
  *) { [ "$batch" -ge 1 ] && [ "$batch" -le 512 ]; } || { echo "FAIL: OTEL_BSP_MAX_EXPORT_BATCH_SIZE is $batch, expected 1 to 512"; fail=1; } ;;
esac
case "$delay" in
  ''|*[!0-9]*) echo "FAIL: OTEL_BSP_SCHEDULE_DELAY must be a number of milliseconds, found '$delay'"; fail=1 ;;
  *) { [ "$delay" -ge 100 ] && [ "$delay" -le 5000 ]; } || { echo "FAIL: OTEL_BSP_SCHEDULE_DELAY is $delay, expected 100 to 5000"; fail=1; } ;;
esac

if [ "$fail" -eq 0 ]; then
  deadline=$((SECONDS + 150))
  seen=0
  while [ "$SECONDS" -lt "$deadline" ]; do
    recent="$(kubectl -n starfleet logs deployment/collector --since=45s 2>/dev/null || true)"
    from_pod="$(printf '%s\n' "$recent" | grep -c "service.instance.id: Str($pod)" || true)"
    span_names="$(printf '%s\n' "$recent" | grep -Ec 'Name +: shuttle\.(dock|launch|scan)$' || true)"
    if [ "$from_pod" -ge 1 ] && [ "$span_names" -ge 1 ]; then
      seen=1
      break
    fi
    sleep 5
  done
  if [ "$seen" -ne 1 ]; then
    echo "FAIL: the Collector log of the last 45 seconds has no shuttle span from $pod"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the trace pipeline samples at $arg, batches spans and delivers them"
fi
exit "$fail"
