# Overview: SDK Components And Extension Contracts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example application and a Collector, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the SDK components through environment variables, read what the application and the Collector print, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. You need `jq` on your machine for the `shuttle_env` helper.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployment `shuttle` | A Python service that records spans, a counter, a histogram and log records every three seconds. |
  | ConfigMap `shuttle-app` | The Python file `app.py`, with a custom span processor `CrewTagProcessor` that the variable `SHUTTLE_SPAN_PROCESSORS` can switch on. |
  | Deployment `collector` | An OpenTelemetry Collector with the `debug` exporter. It prints every span, metric and log record it receives. |
  | Service `collector` | Port 4317 for gRPC and port 4318 for HTTP. |

- Standard variables on the `shuttle` Deployment: `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_METRIC_EXPORT_INTERVAL` and `OTEL_BSP_SCHEDULE_DELAY`. Application-specific: `SHUTTLE_SPAN_PROCESSORS` (a comma-separated list of `simple`, `batch` and `crew-tag`) and `SHUTTLE_CONFIGURE_SDK`.
- Every restart of the `shuttle` pod takes a minute or more because it installs its packages with `pip`. Use `kubectl -n starfleet rollout status deploy/shuttle --timeout=300s` after each change.

## Helpers

Paste these once in each new terminal. `pipeline` prints the start-up line of the application, with the processors, the sampler and the propagator. `received` prints the lines of the last minute of Collector output that match a word. `shuttle_env` lists the environment of the `shuttle` container.

```sh
pipeline() {
  kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
}
received() {
  kubectl -n starfleet logs deploy/collector --since=60s | grep "$1"
}
shuttle_env() {
  kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
}
```

## Practice tasks

- Set `OTEL_BSP_SCHEDULE_DELAY=15000` and watch the Collector output arrive in bursts. Then set `SHUTTLE_SPAN_PROCESSORS=simple` and explain the difference.
- Set `OTEL_TRACES_SAMPLER=parentbased_traceidratio` and `OTEL_TRACES_SAMPLER_ARG=0.5`. Read the sampler description in `pipeline`.
- Set `OTEL_TRACES_SAMPLER=always_off` and check that metrics and log records still arrive while spans do not.
- Set `OTEL_BSP_MAX_QUEUE_SIZE=2` and `OTEL_BSP_MAX_EXPORT_BATCH_SIZE=2`. Compare how many `plot-course` spans reach the Collector with the number the application creates, and explain the difference.
- Set `OTEL_PROPAGATORS=b3` and read the failure in the `shuttle` log. Explain why the process cannot start.
