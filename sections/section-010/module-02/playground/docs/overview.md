# Overview: Attributes, Metric Points And Exemplars (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with an OpenTelemetry Collector and one instrumented service, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the configuration, read the telemetry, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- In the `starfleet` namespace:

  | Object | What it is |
  | --- | --- |
  | Deployment `collector` | The OpenTelemetry Collector. It receives OTLP on ports 4317 (gRPC) and 4318 (HTTP) and prints every trace, metric and log record with the `debug` exporter (`verbosity: detailed`) |
  | ConfigMap `collector-config` | The Collector configuration |
  | Deployment `shuttle` | A Python program built on the OpenTelemetry SDK. It handles one simulated request per second and records a span, a log record and metrics for it |
  | ConfigMap `shuttle-app` | The program (`app.py`), mounted at `/app` |

- The shuttle service sends cumulative metrics and an exemplar filter set to always_off, so no data point carries an exemplar.
- The `shuttle` pod runs `pip install` before it starts. Allow two to five minutes after the cluster starts before telemetry appears.

## Helpers

Paste these once in each new terminal. `collector_log` prints the last part of the Collector output. `shuttle_env` prints the `OTEL_*` variables of the `shuttle` Deployment.

```sh
collector_log() {
  kubectl -n starfleet logs deploy/collector --since="${1:-30s}"
}
shuttle_env() {
  kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
}
```

Use them like this: `shuttle_env`, `collector_log 20s | head -80`. Change a variable with `kubectl -n starfleet set env deploy/shuttle NAME=value` and wait with `kubectl -n starfleet rollout status deploy/shuttle --timeout=300s`.

## Ideas to try

- Find the metric `shuttle.requests` in the Collector log and read its unit, data type, monotonicity and temporality.
- Set `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta`, wait for the rollout and compare the data points of `shuttle.requests` and `shuttle.queue.depth`. Explain why one changed and the other did not.
- Set `OTEL_METRICS_EXEMPLAR_FILTER=trace_based` and find an exemplar on `shuttle.request.duration`. Compare its trace ID with a span in the log.
- Compare the start timestamp and the timestamp of two cumulative data points of the same series.
- Find the attributes of the `shuttle.request.duration` data points and count how many series one route creates.
