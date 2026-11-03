#!/usr/bin/env bash
# Check: every fresh ERROR record carries a 32-character trace ID.
set -uo pipefail

NS=starfleet
# The shuttle needs a minute to install the SDK after every change, so every
# check polls (up to about 150 seconds) for fresh records in the collector log.
fresh_logs() { kubectl -n "$NS" logs deploy/collector --since="${1:-20}s" 2>/dev/null; }
wait_until() {
  local check="$1" i
  for i in $(seq 1 50); do
    if "$check"; then return 0; fi
    sleep 3
  done
  return 1
}

inside="$(kubectl -n "$NS" get deployment shuttle -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name == "SHUTTLE_LOG_INSIDE_SPAN") | .value' | head -n 1)"
if [ "$(echo "$inside" | tr A-Z a-z)" = "false" ]; then
  echo "FAIL: SHUTTLE_LOG_INSIDE_SPAN is still false: the error record is written after the span has ended"
  exit 1
fi

# Prints "<number of ERROR records> <number of ERROR records without a trace ID>".
count_error_records() {
  fresh_logs 30 | awk '
    function flush() { if (inrec && sev == "ERROR") { errs++; if (!tid) bad++ } inrec = 0; sev = ""; tid = 0 }
    /LogRecord #/ { flush(); inrec = 1; next }
    /ResourceLog|ResourceSpans|ResourceMetrics/ { flush(); next }
    inrec && /SeverityText:/ { sev = $2 }
    inrec && /Trace ID:/ { if (length($3) == 32) tid = 1 }
    END { flush(); print errs + 0, bad + 0 }'
}

errors_correlated() {
  local result errs bad
  result="$(count_error_records)"
  errs="${result% *}"
  bad="${result#* }"
  [ "$errs" -ge 1 ] && [ "$bad" -eq 0 ]
}

if wait_until errors_correlated; then
  echo "PASS: fresh ERROR records arrive and every one carries a trace ID"
  exit 0
fi
echo "FAIL: ERROR records without a trace ID still arrive, or no fresh ERROR record arrives"
exit 1
