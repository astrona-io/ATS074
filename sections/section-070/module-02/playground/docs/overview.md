# Overview: Collector Agent And Gateway Roles (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with two Collectors in different roles and an application that uses the OpenTelemetry SDK, and then waits. There is no task, no `astrona submit` and no pass or fail. Change a configuration, restart a Collector, read the logs, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it. You need `jq` on your machine.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployment `shuttle` | A Python app that uses the OpenTelemetry SDK: a `plan-jump` span with a child `engage-drive` span, and a counter `shuttle.jumps`. It reads `OTEL_EXPORTER_OTLP_ENDPOINT=http://agent:4318` |
  | DaemonSet `agent` | A Collector in the agent role (contrib 0.164.0). ConfigMap `agent-config`. Environment `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=starfleet-lab` |
  | Service `agent` | Ports 4317 and 4318, with `internalTrafficPolicy: Local` so a client reaches the agent pod on its own node |
  | Deployment `gateway` | A Collector in the gateway role. ConfigMap `gateway-config`. The `debug` exporter prints all data |

- The agent pipelines use `memory_limiter`, `resourcedetection` (detectors `env` and `system`) and `batch`, in this order, and export with `otlp` to `gateway:4317`.
- The `shuttle` pod needs about one minute after the start, because it installs the SDK first.

## Helpers

Paste these once in each new terminal. `agent_config` prints the agent configuration. `gateway_log` prints the last minute of the gateway log. `agent_restart` reloads the agent, because a Collector reads its configuration only when it starts.

```sh
agent_config() {
  kubectl -n starfleet get configmap agent-config -o jsonpath='{.data.config\.yaml}'
}
gateway_log() {
  kubectl -n starfleet logs deploy/gateway --since="${1:-60}s"
}
agent_restart() {
  kubectl -n starfleet rollout restart daemonset/agent && kubectl -n starfleet rollout status daemonset/agent --timeout=300s
}
```

## Practice tasks

- Run `gateway_log | grep -E 'service.name|host.name|deployment.environment.name'` and decide which attribute came from the application and which came from the agent.
- Run `kubectl -n starfleet logs daemonset/agent | head -30` and find the line where the Collector lists its pipelines and processors.
- Move `memory_limiter` to the end of both pipelines, run `agent_restart` and read the agent log. Move it back.
- Set `override: true` under `resourcedetection`. Set `OTEL_RESOURCE_ATTRIBUTES` on `shuttle` to `deployment.environment.name=app` with `kubectl set env`. Compare the value at the gateway before and after.
- Delete the `gateway` Deployment, wait 30 seconds, watch the agent log and then recreate it by reapplying the manifest. Decide what the agent did with the data in between.
- Run `kubectl -n starfleet get daemonset agent -o json | jq '.spec.template.spec.volumes'` and list every host path the agent can read. Decide whether the receivers it uses need any of them.
