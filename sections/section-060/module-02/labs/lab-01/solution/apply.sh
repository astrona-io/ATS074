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
kubectl -n "$NS" set env deployment/probe OTEL_PROPAGATORS=tracecontext,baggage
kubectl -n "$NS" set env deployment/shuttle SHUTTLE_BAGGAGE=mission=survey
rollout probe
rollout shuttle
wait_probe_line
kubectl -n "$NS" create configmap propagation-policy \
  --from-literal=propagators=tracecontext,baggage \
  --from-literal=baggage-keys=mission \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[solution] Applied."
