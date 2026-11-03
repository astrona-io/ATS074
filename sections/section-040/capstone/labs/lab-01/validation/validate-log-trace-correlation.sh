#!/usr/bin/env bash
# Check: every fresh ERROR record has a trace ID, and that trace ID belongs to a
# span that the collector also received.
set -uo pipefail

NS=starfleet
# The shuttle needs a minute to install the SDK after every change, so every
# check polls (up to about 150 seconds) for fresh telemetry in the collector log.
fresh_logs() { kubectl -n "$NS" logs deploy/collector --since="${1:-20}s" 2>/dev/null; }
wait_until() {
  local check="$1" i
  for i in $(seq 1 50); do
    if "$check"; then return 0; fi
    sleep 3
  done
  return 1
}

# One trace ID per ERROR log record of the last 30 seconds (empty if it has none).
error_trace_ids() {
  fresh_logs 30 | awk '
    function flush() { if (inrec && sev == "ERROR") print (length(tid) == 32 ? tid : "NONE") ; inrec = 0; sev = ""; tid = "" }
    /LogRecord #/ { flush(); inrec = 1; next }
    /ResourceLog|ResourceSpans|ResourceMetrics/ { flush(); next }
    inrec && /SeverityText:/ { sev = $2 }
    inrec && /Trace ID:/ { tid = $3 }
    END { flush() }'
}

# Trace IDs of the spans of the last 60 seconds.
span_trace_ids() {
  fresh_logs 60 | awk '
    /Span #/ { inspan = 1; next }
    /LogRecord #|ResourceLog|ResourceMetrics|ResourceSpans/ { inspan = 0 }
    inspan && /Trace ID/ { print $NF }'
}

errors_join_spans() {
  local ids spans id
  ids="$(error_trace_ids)"
  [ -n "$ids" ] || return 1
  spans="$(span_trace_ids)"
  for id in $ids; do
    [ "$id" != "NONE" ] || return 1
    echo "$spans" | grep -qx "$id" || return 1
  done
  return 0
}

if wait_until errors_join_spans; then
  echo "PASS: every fresh ERROR record carries the trace ID of a span the collector received"
  exit 0
fi
echo "FAIL: an ERROR record has no trace ID, or its trace has no span in the collector, or no fresh ERROR record arrives"
exit 1
