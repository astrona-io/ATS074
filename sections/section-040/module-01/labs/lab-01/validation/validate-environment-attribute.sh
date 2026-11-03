#!/usr/bin/env bash
# Check: the resource carries deployment.environment.name=lab and keeps service.version=1.0.0.
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

attrs="$(shuttle_env OTEL_RESOURCE_ATTRIBUTES)"
case ",$attrs," in
  *,deployment.environment.name=lab,*) ;;
  *) echo "FAIL: OTEL_RESOURCE_ATTRIBUTES is '${attrs}'; add deployment.environment.name=lab"; exit 1 ;;
esac
case ",$attrs," in
  *,service.version=1.0.0,*) ;;
  *) echo "FAIL: OTEL_RESOURCE_ATTRIBUTES lost service.version=1.0.0"; exit 1 ;;
esac
if wait_log 'deployment\.environment\.name: Str\(lab\)'; then
  echo "PASS: the Collector received spans with deployment.environment.name lab"
  exit 0
fi
echo "FAIL: no span with deployment.environment.name lab in the last 2 minutes; wait for the new pod to start"
exit 1
