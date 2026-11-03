#!/usr/bin/env bash
# Check: a failed report span has status Error and an exception event in the Collector log.
set -uo pipefail

recent_logs() { kubectl -n starfleet logs deploy/collector --since=120s 2>/dev/null; }
# Poll the Collector log for up to about 2 minutes. $1 is an awk or grep -E check run by the caller.
wait_log() {
  for _ in $(seq 1 24); do
    if recent_logs | grep -Eq "$1"; then return 0; fi
    sleep 5
  done
  return 1
}
shuttle_env() {
  kubectl -n starfleet get deployment shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" ".spec.template.spec.containers[0].env[]? | select(.name==\$n) | .value"
}

for _ in $(seq 1 30); do
  if recent_logs | awk '
    function flush() { if (name == "report" && status == "Error" && exc) ok = 1; name = ""; status = ""; exc = 0 }
    /^ *ResourceSpans #/ { flush() }
    /^ *Span #[0-9]+/ { flush() }
    /^ *Name *: / { sub(/^[^:]*: ?/, ""); name = $0 }
    /^ *Status code *: / { sub(/^[^:]*: ?/, ""); status = $0 }
    /-> Name: exception/ { exc = 1 }
    END { flush(); exit ok ? 0 : 1 }'; then
    echo "PASS: a failed report span has status Error and an exception event"
    exit 0
  fi
  sleep 5
done
echo "FAIL: no report span with status Error and an exception event in the last 2.5 minutes (a failure happens every third trace)"
exit 1
