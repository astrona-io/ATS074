set -euo pipefail
NS=starfleet
rollout() { kubectl -n "$NS" rollout status "deployment/$1" --timeout=300s; }
wait_probe_line() {
  # Waits for a probe line from the newest probe pod that has a remote parent.
  for i in $(seq 1 60); do
    pod="$(kubectl -n "$NS" get pods -l app=probe -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | sort_by(.metadata.creationTimestamp) | last | .metadata.name')"
    if kubectl -n "$NS" logs "$pod" --tail=-1 2>/dev/null | grep '^PROPAGATION' | grep ' remote=true ' | grep -qv ' parent_span_id=none '; then return 0; fi
    sleep 5
  done
  echo "[solution] no continued trace in the probe log" >&2
  return 1
}
kubectl -n "$NS" set env deployment/shuttle OTEL_PROPAGATORS=tracecontext,baggage SHUTTLE_ATTACH_CONTEXT=true SHUTTLE_BAGGAGE=mission=survey
kubectl -n "$NS" set env deployment/probe OTEL_PROPAGATORS=tracecontext,baggage PROBE_BAGGAGE_ATTRIBUTES=mission
rollout probe
rollout shuttle
wait_probe_line
sleep 15
pod="$(kubectl -n "$NS" get pods -l app=probe -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | sort_by(.metadata.creationTimestamp) | last | .metadata.name')"
trace_id="$(kubectl -n "$NS" logs "$pod" --tail=-1 | grep '^PROPAGATION' | grep ' remote=true ' | tail -n 2 | head -n 1 | sed 's/.* trace_id=\([^ ]*\).*/\1/')"
kubectl -n "$NS" create configmap propagation-report \
  --from-literal=trace-id="$trace_id" \
  --from-literal=propagators=tracecontext,baggage \
  --from-literal=baggage-keys=mission \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[solution] Applied."
