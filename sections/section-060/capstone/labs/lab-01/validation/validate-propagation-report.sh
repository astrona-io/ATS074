#!/usr/bin/env bash
# ConfigMap propagation-report names one trace seen end to end.
set -uo pipefail

NS=starfleet

newest_pod() {
  kubectl -n "$NS" get pods -l "app=$1" -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp == null) | select(.status.phase == "Running")] | sort_by(.metadata.creationTimestamp) | last | .metadata.name // empty'
}

# PROPAGATION lines of the newest running pod of an app (shuttle or probe).
trace_lines() {
  local pod
  pod="$(newest_pod "$1")"
  [ -n "$pod" ] || return 0
  kubectl -n "$NS" logs "$pod" --tail=-1 2>/dev/null | grep '^PROPAGATION' || true
}

# Reads lines on stdin and prints the value of one key=value field.
field() { sed -n "s/.* $1=\([^ ]*\).*/\1/p"; }

env_value() {
  kubectl -n "$NS" get deployment "$1" -o json 2>/dev/null | jq -r --arg name "$2" '.spec.template.spec.containers[0].env[]? | select(.name == $name) | .value'
}

# wait_for SECONDS COMMAND...: polls the command every 5 seconds.
wait_for() {
  local limit="$1" end
  shift
  end=$((SECONDS + limit))
  while [ "$SECONDS" -lt "$end" ]; do
    if "$@"; then return 0; fi
    sleep 5
  done
  return 1
}

client_trace_ids() { trace_lines shuttle | grep ' role=client ' | field trace_id; }

# True when a probe span has a remote parent that belongs to a trace the shuttle started.
trace_continued() {
  local clients line trace_id
  clients="$(client_trace_ids)"
  [ -n "$clients" ] || return 1
  while read -r line; do
    trace_id="$(printf '%s\n' "$line" | field trace_id)"
    if printf '%s\n' "$clients" | grep -qxF "$trace_id"; then return 0; fi
  done < <(trace_lines probe | grep ' role=server ' | grep ' remote=true ' | grep -v ' parent_span_id=none ')
  return 1
}

# True when a worker thread span has a parent in a trace the shuttle started.
worker_attached() {
  local clients line trace_id
  clients="$(client_trace_ids)"
  [ -n "$clients" ] || return 1
  while read -r line; do
    trace_id="$(printf '%s\n' "$line" | field trace_id)"
    if printf '%s\n' "$clients" | grep -qxF "$trace_id"; then return 0; fi
  done < <(trace_lines shuttle | grep ' role=worker ' | grep -v ' parent_span_id=none ')
  return 1
}

# True when recent shuttle and probe lines carry the mission baggage and no session-token.
secret_absent() {
  local sent received
  sent="$(trace_lines shuttle | grep ' role=client ' | tail -n 3)"
  received="$(trace_lines probe | grep ' role=server ' | tail -n 3)"
  [ -n "$sent" ] && [ -n "$received" ] || return 1
  if printf '%s\n%s\n' "$sent" "$received" | grep -q 'session-token'; then return 1; fi
  printf '%s\n' "$received" | grep -q 'baggage=mission=survey' || return 1
  return 0
}

read_key() { kubectl -n "$NS" get configmap propagation-report -o json 2>/dev/null | jq -r --arg key "$1" '.data[$key] // empty'; }
trace_id="$(read_key trace-id)"
propagators="$(read_key propagators)"
keys="$(read_key baggage-keys)"
if [ -z "$trace_id" ] || [ -z "$propagators" ] || [ -z "$keys" ]; then
  echo "FAIL: ConfigMap propagation-report needs the keys trace-id, propagators and baggage-keys"
  exit 1
fi
printf '%s' "$trace_id" | grep -Eq '^[0-9a-f]{32}$' || { echo "FAIL: trace-id must be 32 lowercase hex characters"; exit 1; }
[ "$propagators" = "tracecontext,baggage" ] || { echo "FAIL: propagators must be tracecontext,baggage"; exit 1; }
[ "$keys" = "mission" ] || { echo "FAIL: baggage-keys must be mission"; exit 1; }
trace_lines shuttle | grep ' role=client ' | grep -q " trace_id=${trace_id} " || { echo "FAIL: the shuttle never logged a dispatch span in trace ${trace_id}"; exit 1; }
trace_lines shuttle | grep ' role=worker ' | grep " trace_id=${trace_id} " | grep -qv ' parent_span_id=none ' || { echo "FAIL: no worker span with a parent in trace ${trace_id}"; exit 1; }
trace_lines probe | grep ' role=server ' | grep " trace_id=${trace_id} " | grep ' remote=true ' | grep -qv ' parent_span_id=none ' || { echo "FAIL: the probe has no span with a remote parent in trace ${trace_id}"; exit 1; }
pod="$(newest_pod collector)"
kubectl -n "$NS" logs "$pod" --tail=-1 2>/dev/null | grep -q "$trace_id" || { echo "FAIL: the collector never logged trace ${trace_id}"; exit 1; }
echo "PASS: trace ${trace_id} is in the shuttle logs, the probe logs and the collector logs"
