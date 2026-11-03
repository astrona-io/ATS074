#!/usr/bin/env bash
# ConfigMap traceparent-evidence matches a traceparent the probe received.
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

read_key() { kubectl -n "$NS" get configmap traceparent-evidence -o json 2>/dev/null | jq -r --arg key "$1" '.data[$key] // empty'; }
version="$(read_key version)"
trace_id="$(read_key trace-id)"
parent_id="$(read_key parent-id)"
flags="$(read_key trace-flags)"
if [ -z "$version" ] || [ -z "$trace_id" ] || [ -z "$parent_id" ] || [ -z "$flags" ]; then
  echo "FAIL: ConfigMap traceparent-evidence needs the keys version, trace-id, parent-id and trace-flags"
  exit 1
fi
[ "$version" = "00" ] || { echo "FAIL: version must be 00"; exit 1; }
printf '%s' "$trace_id" | grep -Eq '^[0-9a-f]{32}$' || { echo "FAIL: trace-id must be 32 lowercase hex characters"; exit 1; }
printf '%s' "$parent_id" | grep -Eq '^[0-9a-f]{16}$' || { echo "FAIL: parent-id must be 16 lowercase hex characters"; exit 1; }
printf '%s' "$flags" | grep -Eq '^[0-9a-f]{2}$' || { echo "FAIL: trace-flags must be 2 hex characters"; exit 1; }
if ! trace_lines probe | grep ' role=server ' | grep -qF " traceparent=${version}-${trace_id}-${parent_id}-${flags} "; then
  echo "FAIL: the probe never logged traceparent=${version}-${trace_id}-${parent_id}-${flags}"
  exit 1
fi
if ! trace_lines shuttle | grep ' role=client ' | grep " trace_id=${trace_id} " | grep -q " span_id=${parent_id} "; then
  echo "FAIL: parent-id is not the span ID of the shuttle.dispatch span of that trace"
  exit 1
fi
echo "PASS: traceparent-evidence matches a header the probe received and the dispatch span that sent it"
