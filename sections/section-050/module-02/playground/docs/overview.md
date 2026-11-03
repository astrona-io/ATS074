# Overview: Metric And Log Pipelines (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with an OpenTelemetry Collector and a small Python service, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the configuration of the service, read what the Collector receives, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. You need `jq` on your machine for the helpers.
- The example application in the `starfleet` namespace:

  | Object | What it is |
  | --- | --- |
  | Deployment `collector` and Service `collector` | The OpenTelemetry Collector. It receives OTLP on ports 4317 (gRPC) and 4318 (HTTP) and prints every span, metric and log record to its own log with the `debug` exporter at `detailed` verbosity |
  | Deployment `shuttle` | A Python service built with the OpenTelemetry SDK. It handles a fake request every 500 milliseconds and records spans, three metrics and one log record per request |
  | ConfigMap `shuttle-app` | The Python script of the `shuttle` |

- The metrics are the counter `shuttle.requests` (attributes `shuttle.route` and `shuttle.client`), the histogram `shuttle.request.duration` (attribute `shuttle.route`) and the counter `shuttle.fuel.used`.
- The `shuttle` pod runs `pip install` for the SDK before it starts, so it needs a few minutes. Wait until `kubectl -n starfleet get pods` shows both pods ready.
- The starting values are `OTEL_METRIC_EXPORT_INTERVAL=10000`, `OTEL_BLRP_SCHEDULE_DELAY=2000` and no views. The variables that start with `SHUTTLE_` belong to this example script. `SHUTTLE_VIEWS` takes a comma list of `keys` (keep only `shuttle.route` on `shuttle.requests`), `buckets` (explicit histogram bucket boundaries 0.05, 0.1, 0.25, 0.5 and 1.0) and `drop-fuel` (drop the `shuttle.fuel.used` stream). The script also reads `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` (`cumulative` or `delta`).
- Every environment change restarts the pod, because the Deployment uses the `Recreate` strategy.

## Helpers

Paste these once in each new terminal. `shuttle_env` prints the environment of the `shuttle` container. `shuttle_config` prints the line the script writes at start. `collector_recent` prints what the Collector received in the last 30 seconds, or in the period you pass. `set_shuttle_env` changes one variable and waits for the new pod.

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

- Run `collector_recent 40s | grep -E 'Name:|shuttle\.(client|route)'` and list the metric names and attributes you see.
- Run `set_shuttle_env SHUTTLE_VIEWS=keys` and look again. Find out which attribute disappeared and which component removed it.
- Run `set_shuttle_env SHUTTLE_VIEWS=keys,drop-fuel` and check that the `shuttle.fuel.used` metric no longer reaches the Collector although the script still calls `add` on it.
- Run `set_shuttle_env OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta` and find the `AggregationTemporality` line of the counter.
- Set `OTEL_METRIC_EXPORT_INTERVAL=60000` and watch how long the Collector stays silent about metrics while spans and logs keep arriving.
- Find a log record in `collector_recent` and check that it carries a trace ID and a span ID. Compare with the span of the same request.
