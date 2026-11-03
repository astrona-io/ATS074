# Overview: Exporter, Sampler And Declarative Configuration (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Change the exporter, sampler and interval settings, read the effect in the service log and the Collector log, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Namespace `starfleet` with two Deployments:

  | Deployment | What it is |
  | --- | --- |
  | `shuttle` | A Python service that uses the real OpenTelemetry SDK. Every two seconds it creates a span `dock` with a child span `scan`, increments the counter `shuttle.docks` and records the histogram `shuttle.dock.duration`. It prints `shuttle: run N recording=True` or `recording=False` for each run. It exports over OTLP/HTTP and has only the HTTP exporter installed. |
  | `collector` | The OpenTelemetry Collector with an OTLP receiver (gRPC 4317, HTTP 4318) and the `debug` exporter with detailed verbosity. Its pod log is the evidence of what arrived. |

- The `shuttle` pod installs the SDK with `pip` when it starts, so a new pod needs about a minute. Wait with `kubectl -n starfleet rollout status deploy/shuttle --timeout=300s` after each change.
- The service reads `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_TRACES_SAMPLER`, `OTEL_TRACES_SAMPLER_ARG`, `OTEL_BSP_*` and `OTEL_METRIC_EXPORT_INTERVAL` from its Deployment.

## Helpers

Paste these once in each new terminal. `shuttle_env` prints the environment of the `shuttle` Deployment. `collector_recent` prints the Collector log of the last `$1` seconds. `count_spans` counts the `dock` spans in that window.

```sh
shuttle_env() {
  kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
}
collector_recent() {
  kubectl -n starfleet logs deploy/collector --since="${1:-30}s"
}
count_spans() {
  collector_recent "${1:-30}" | grep -Ec 'Name +: dock'
}
```

## Practice tasks

- Set `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` and read why the service stops. Decide which package a gRPC exporter would need.
- Set a `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` with and without `/v1/traces` and compare `count_spans` and the metrics.
- Set `OTEL_TRACES_SAMPLER=traceidratio` without an argument and read the sampler line in the service log.
- Set `OTEL_BSP_SCHEDULE_DELAY=20000` and measure how long a new span takes to appear at the Collector.
- Set `OTEL_EXPORTER_OTLP_TIMEOUT=1` and read the export errors. Decide what a too-short timeout does to a healthy Collector.
