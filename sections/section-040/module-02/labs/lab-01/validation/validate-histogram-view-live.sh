#!/usr/bin/env bash
# Check: the live histogram data points in the Collector log have no request.id
# attribute, keep http.route and carry the boundary 0.05 that only the new View
# sets (the default boundaries are 0, 5, 10, 25, 50, 75, 100, 250, 500, ...).
# An old pod can still be in the log right after a restart, so the script polls
# for up to 120 seconds until the log shows the expected result.
set -uo pipefail

metric_block() {
  awk -v name="$1" '/^Metric #/ {show=0} $0 ~ "-> Name: " name " *$" {show=1} show {print}'
}

deadline=$((SECONDS + 120))
while true; do
  block="$(kubectl -n starfleet logs deploy/collector --since=45s 2>/dev/null | metric_block shuttle.request.duration)"
  seen_bounds=0; has_request_id=0; has_route=0; has_new_bound=0
  echo "$block" | grep -q 'ExplicitBounds' && seen_bounds=1
  echo "$block" | grep -q 'request\.id:' && has_request_id=1
  echo "$block" | grep -q 'http\.route:' && has_route=1
  echo "$block" | grep -Eq 'ExplicitBounds #[0-9]+: 0\.050000' && has_new_bound=1
  if [ "$seen_bounds" = 1 ] && [ "$has_request_id" = 0 ] && [ "$has_route" = 1 ] && [ "$has_new_bound" = 1 ]; then
    echo "PASS: the live histogram has no request.id and uses the View boundaries"
    exit 0
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    break
  fi
  sleep 5
done

if [ "$seen_bounds" = 0 ]; then
  echo "FAIL: after 120 seconds the Collector log of the last 45 seconds has no histogram data points for shuttle.request.duration"
  exit 1
fi
[ "$has_request_id" = 0 ] || echo "FAIL: the histogram data points still carry the request.id attribute"
[ "$has_route" = 1 ] || echo "FAIL: the histogram data points lost http.route, which the View must keep"
[ "$has_new_bound" = 1 ] || echo "FAIL: the histogram does not use the boundary 0.05 from the View"
exit 1
