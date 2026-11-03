#!/usr/bin/env bash
# Check: the ConfigMap shuttle-views defines a View for the histogram that
# selects the instrument, lists the attribute keys without request.id and uses
# explicit buckets. This reads the file. The live result is checked in another
# script.
set -uo pipefail

fail=0

if ! kubectl -n starfleet get configmap shuttle-views >/dev/null 2>&1; then
  echo "FAIL: ConfigMap shuttle-views not found in starfleet"
  exit 1
fi

views="$(kubectl -n starfleet get configmap shuttle-views -o json | jq -r '.data["views.py"] // ""')"
# Remove comment lines so that a word in a comment cannot pass the check.
code="$(echo "$views" | grep -v '^[[:space:]]*#')"

if ! echo "$code" | grep -q 'View('; then
  echo "FAIL: views.py has no View(...) in VIEWS"
  fail=1
fi
if ! echo "$code" | grep -Eq 'instrument_name *= *["'"'"']shuttle\.request\.duration["'"'"']'; then
  echo "FAIL: no View selects instrument_name=\"shuttle.request.duration\""
  fail=1
fi
if ! echo "$code" | grep -q 'attribute_keys'; then
  echo "FAIL: the View has no attribute_keys"
  fail=1
fi
if ! echo "$code" | grep -q 'http\.route' || ! echo "$code" | grep -q 'http\.response\.status_code'; then
  echo "FAIL: attribute_keys must keep http.route and http.response.status_code"
  fail=1
fi
if echo "$code" | grep -q 'request\.id'; then
  echo "FAIL: request.id must not be kept in views.py"
  fail=1
fi
if ! echo "$code" | grep -q 'ExplicitBucketHistogramAggregation'; then
  echo "FAIL: the View must use ExplicitBucketHistogramAggregation"
  fail=1
fi
for bound in 0.01 0.05 0.1 0.25 0.5 1.0; do
  if ! echo "$code" | grep -Eq "(^|[^0-9.])${bound//./\\.}([^0-9]|$)"; then
    echo "FAIL: the bucket boundary $bound is missing"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle-views defines the View for shuttle.request.duration"
fi
exit "$fail"
