#!/usr/bin/env bash
# Check: the Collector log of the last 45 seconds shows the metrics with the
# expected temporality. The program exports every 10 seconds after the fix, and
# an old pod can still be in the log right after a restart, so the script polls
# for up to 120 seconds until the log shows the expected result. A change that
# is not live yet, or a metric invented by hand, cannot pass.
set -uo pipefail

metric_block() {
  # Prints the log lines of one metric, from its Name line to the next metric.
  awk -v name="$1" '/^Metric #/ {show=0} $0 ~ "-> Name: " name " *$" {show=1} show {print}'
}

temporality_of() {
  # $1 = log text, $2 = metric name. Prints the last AggregationTemporality.
  echo "$1" | metric_block "$2" | grep 'AggregationTemporality:' | tail -1 | sed 's/.*AggregationTemporality: *//'
}

deadline=$((SECONDS + 120))
while true; do
  log="$(kubectl -n starfleet logs deploy/collector --since=45s 2>/dev/null || true)"
  requests="$(temporality_of "$log" shuttle.requests)"
  duration="$(temporality_of "$log" shuttle.request.duration)"
  depth="$(temporality_of "$log" shuttle.queue.depth)"
  if [ "$requests" = "Delta" ] && [ "$duration" = "Delta" ] && [ "$depth" = "Cumulative" ]; then
    echo "PASS: counter and histogram are Delta, the up-down counter is Cumulative"
    exit 0
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    break
  fi
  sleep 5
done

echo "FAIL: after 120 seconds the Collector log of the last 45 seconds shows:"
echo "  shuttle.requests         = '${requests:-not seen}' (expected Delta)"
echo "  shuttle.request.duration = '${duration:-not seen}' (expected Delta)"
echo "  shuttle.queue.depth      = '${depth:-not seen}' (expected Cumulative)"
exit 1
