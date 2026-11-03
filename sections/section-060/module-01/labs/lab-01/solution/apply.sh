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
kubectl -n "$NS" set env deployment/shuttle SHUTTLE_ATTACH_CONTEXT=true
rollout shuttle
wait_probe_line
line="$(kubectl -n "$NS" logs "$(kubectl -n "$NS" get pods -l app=probe -o jsonpath='{.items[0].metadata.name}')" --tail=-1 | grep '^PROPAGATION' | grep -v ' traceparent=none ' | tail -n 1)"
header="$(printf '%s\n' "$line" | sed 's/.* traceparent=\([^ ]*\).*/\1/')"
kubectl -n "$NS" create configmap traceparent-evidence \
  --from-literal=version="$(echo "$header" | cut -d- -f1)" \
  --from-literal=trace-id="$(echo "$header" | cut -d- -f2)" \
  --from-literal=parent-id="$(echo "$header" | cut -d- -f3)" \
  --from-literal=trace-flags="$(echo "$header" | cut -d- -f4)" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[solution] Applied."
