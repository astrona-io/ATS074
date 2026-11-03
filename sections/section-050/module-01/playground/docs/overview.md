# Overview: Trace Pipeline (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with an OpenTelemetry Collector and a small Python service, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the configuration of the service, read what the Collector receives, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. You need `jq` on your machine for the helpers.
- The example application in the `starfleet` namespace:

  | Object | What it is |
  | --- | --- |
  | Deployment `collector` and Service `collector` | The OpenTelemetry Collector. It receives OTLP on ports 4317 (gRPC) and 4318 (HTTP) and prints every span, metric and log record to its own log with the `debug` exporter at `detailed` verbosity |
  | Deployment `shuttle` | A Python service built with the OpenTelemetry SDK. It handles a fake request every 500 milliseconds and records spans, metrics and logs |
  | ConfigMap `shuttle-app` | The Python script of the `shuttle` |
  | ConfigMap `collector-config` | The Collector configuration |

- The `shuttle` pod runs `pip install` for the SDK before it starts, so it needs a few minutes. Wait until `kubectl -n starfleet get pods` shows both pods ready.
- The SDK is configured only with environment variables on the `shuttle` Deployment. The starting values are `OTEL_TRACES_SAMPLER=parentbased_always_on`, `SHUTTLE_SPAN_PROCESSOR=batch`, `OTEL_BSP_SCHEDULE_DELAY=2000`, `OTEL_METRIC_EXPORT_INTERVAL=10000` and `SHUTTLE_ON_TERM=shutdown`. The variables that start with `SHUTTLE_` belong to this example script. They choose the span processor (`batch` or `simple`) and what the process does when it receives `SIGTERM` (`shutdown` flushes and shuts down the providers, `exit` leaves at once).
- Every environment change restarts the pod, because the Deployment uses the `Recreate` strategy.

## Helpers

Paste these once in each new terminal. `shuttle_env` prints the environment of the `shuttle` container. `shuttle_config` prints the line the script writes at start, which shows what the SDK was told. `collector_recent` prints what the Collector received in the last 30 seconds, or in the period you pass (`collector_recent 2m`). `set_shuttle_env` changes one variable and waits for the new pod.

```sh
shuttle_env() {
  kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + (.value // "(pod field)")'
}
shuttle_config() {
  kubectl -n starfleet logs deploy/shuttle | grep '\[shuttle\] config'
}
collector_recent() {
  kubectl -n starfleet logs deploy/collector --since="${1:-30s}"
}
set_shuttle_env() {
  kubectl -n starfleet set env deploy/shuttle "$1" && kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
}
```

## Practice tasks

- Run `collector_recent | grep -c 'Name           : shuttle'` and count the spans of one run. Then run `set_shuttle_env OTEL_TRACES_SAMPLER=always_off` and count again. Explain which component decided to drop the spans.
- Run `set_shuttle_env OTEL_TRACES_SAMPLER=parentbased_traceidratio`, then `set_shuttle_env OTEL_TRACES_SAMPLER_ARG=0.25`. Count the spans in a one minute window and compare with the always-on count. Write down why the number is only about a quarter.
- Run `set_shuttle_env SHUTTLE_SPAN_PROCESSOR=simple`. Compare how the spans arrive in `collector_recent 10s` with the batching processor: one at a time or in groups.
- Set `OTEL_BSP_MAX_QUEUE_SIZE=1` together with `OTEL_BSP_MAX_EXPORT_BATCH_SIZE=1` and `OTEL_BSP_SCHEDULE_DELAY=30000`. Read `kubectl -n starfleet logs deploy/shuttle` for the SDK warning about a full queue.
- Set `SHUTTLE_ON_TERM=exit` and delete the pod. Compare the last lines of the old pod log with the `shutdown complete` line you get when `SHUTTLE_ON_TERM=shutdown`.
