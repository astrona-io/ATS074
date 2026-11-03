# Overview: Logs, The Logs SDK And Trace Correlation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a small instrumented service and an OpenTelemetry Collector, and then waits. There is no task, no `astrona submit` and no pass or fail. Read records, change the settings of the service, read the records again, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. You need `jq` on your machine for the settings commands.
- Two Deployments in the `starfleet` namespace:

  | Object | What it is |
  | --- | --- |
  | `shuttle` | A Python 3.12 program with the OpenTelemetry SDK 1.45.2. Every three seconds it runs one dispatch inside a span, writes log records with the standard `logging` module through the SDK bridge, emits an event record and counts the dispatch. Every third dispatch fails. |
  | `collector` | The OpenTelemetry Collector (contrib 0.164.0). It receives OTLP on ports 4317 (gRPC) and 4318 (HTTP) and prints every trace, metric and log record with the `debug` exporter, at detailed verbosity. |

- The program is in the ConfigMap `shuttle-app` (key `app.py`). The Collector configuration is in the ConfigMap `collector-config`.
- The `shuttle` is set up through environment variables: the standard `OTEL_*` variables (service name, resource attributes, endpoint, batch delays) and three program settings, `SHUTTLE_LOG_LEVEL`, `SHUTTLE_LOG_PAYLOAD` and `SHUTTLE_LOG_INSIDE_SPAN`.
- The pod installs the SDK with `pip` when it starts, so a new pod needs a minute or two before it exports anything.

## Helpers

Paste this once in each new terminal. `recent_logs` prints the last 45 seconds of the Collector log. `show_env` lists the settings of the `shuttle`.

```sh
recent_logs() { kubectl -n starfleet logs deploy/collector --since=45s; }
show_env() {
  kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
}
```

## Practice tasks

- Print the severity lines of the recent records with `recent_logs | grep -E "SeverityText|SeverityNumber"` and explain why the playground shows no DEBUG record.
- Set `SHUTTLE_LOG_LEVEL=DEBUG` with `kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_LEVEL=DEBUG`, wait for the rollout, and find the `route computed` records.
- Set `SHUTTLE_LOG_INSIDE_SPAN=false` and check that the ERROR records have an empty `Trace ID` line. Explain which line of the program causes it.
- Remove `OTEL_SERVICE_NAME` with `kubectl -n starfleet set env deploy/shuttle OTEL_SERVICE_NAME-` and check the `service.name` of logs, spans and metrics. All three change together. Why?
- Set `OTEL_BLRP_MAX_QUEUE_SIZE=2` and `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE=1` and decide whether records can be lost. Which pod log would show it?
- Run `recent_logs | grep -A6 EventName` and find the attributes of the event.
