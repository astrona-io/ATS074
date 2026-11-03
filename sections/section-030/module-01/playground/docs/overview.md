# Overview: SDK Initialization, Environment Variables And Resources (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Change the configuration of the service, read the effect in the Collector output, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Namespace `starfleet` with two Deployments:

  | Deployment | What it is |
  | --- | --- |
  | `shuttle` | A Python service that uses the real OpenTelemetry SDK. Every two seconds it creates a span `dock` with a child span `scan`, increments the counter `shuttle.docks` and records the histogram `shuttle.dock.duration`. It exports over OTLP/HTTP. |
  | `collector` | The OpenTelemetry Collector with an OTLP receiver (gRPC 4317, HTTP 4318) and the `debug` exporter with detailed verbosity. Its pod log is the evidence of what arrived. |

- The `shuttle` pod installs the SDK with `pip` when it starts, so a new pod needs about a minute before it prints its first line. Wait with `kubectl -n starfleet rollout status deploy/shuttle --timeout=300s` after each change.
- The SDK is configured only by `OTEL_*` environment variables on the `shuttle` Deployment: service name, resource attributes, endpoint, protocol, metric interval and batch delay. The code passes no settings.

## Helpers

Paste these once in each new terminal. `shuttle_env` prints the environment of the `shuttle` Deployment. `collector_recent` prints the Collector log of the last `$1` seconds.

```sh
shuttle_env() {
  kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
}
collector_recent() {
  kubectl -n starfleet logs deploy/collector --since="${1:-30}s"
}
```

## Practice tasks

- Print the resource lines at the Collector with `collector_recent 30 | grep -E 'service\.|deployment\.'` and compare them with `shuttle_env`.
- Set `OTEL_SERVICE_NAME` to an empty value and read the name that arrives. Decide whether an empty value counts as set.
- Set `OTEL_RESOURCE_ATTRIBUTES` to a value with a semicolon between two pairs and find which attributes are lost.
- Set `OTEL_BSP_SCHEDULE_DELAY=abc` and read the service log for the warning. Decide which default applies.
- Set `OTEL_SDK_DISABLED=TRUE` and `OTEL_SDK_DISABLED=1`, one after the other, and compare what the Collector receives.
