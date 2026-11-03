#!/usr/bin/env bash
# Check: log records, spans and metrics all arrive with the same Resource: the
# service name shuttle and the environment training.
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

# Prints "<log blocks> <span blocks> <metric blocks> <blocks without the Resource>".
count_resources() {
  fresh_logs 30 | awk '
    /ResourceLog|ResourceSpans|ResourceMetrics/ {
      if ($0 ~ /ResourceLog/) kind = "logs"; else if ($0 ~ /ResourceSpans/) kind = "spans"; else kind = "metrics"
      seen[kind]++; inres = 1; svc = 0; env = 0; next
    }
    inres && /service.name: Str\(shuttle\)/ { svc = 1 }
    inres && /deployment.environment.name: Str\(training\)/ { env = 1 }
    inres && /ScopeLogs #|ScopeSpans #|ScopeMetrics #/ { if (!(svc && env)) bad++; inres = 0 }
    END { print seen["logs"] + 0, seen["spans"] + 0, seen["metrics"] + 0, bad + 0 }'
}

resource_shared() {
  local result logs spans metrics bad
  result="$(count_resources)"
  set -- $result
  logs="$1"; spans="$2"; metrics="$3"; bad="$4"
  [ "$logs" -ge 1 ] && [ "$spans" -ge 1 ] && [ "$metrics" -ge 1 ] && [ "$bad" -eq 0 ]
}

if wait_until resource_shared; then
  echo "PASS: logs, traces and metrics all carry service.name shuttle and deployment.environment.name training"
  exit 0
fi
echo "FAIL: not every signal reaches the collector with service.name shuttle and deployment.environment.name training"
exit 1
