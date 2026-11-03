#!/usr/bin/env bash
# The three Deployments are available with their original images.
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

fail=0
for name in collector probe shuttle; do
  ready="$(kubectl -n "$NS" get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica"
    fail=1
  fi
done
for name in probe shuttle; do
  image="$(kubectl -n "$NS" get deployment "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ "$image" != "python:3.12-slim" ]; then
    echo "FAIL: deployment $name runs image '$image', expected 'python:3.12-slim'"
    fail=1
  fi
done
image="$(kubectl -n "$NS" get deployment collector -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [ "$image" != "otel/opentelemetry-collector-contrib:0.164.0" ]; then
  echo "FAIL: deployment collector runs image '$image'"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: collector, probe and shuttle are available with their original images"
fi
exit "$fail"
