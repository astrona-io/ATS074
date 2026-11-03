# Overview: API And SDK Separation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example application and a Collector, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the application through its environment variables, read what the Collector receives, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployment `shuttle` | A Python service that creates spans, a counter, a histogram and log records every three seconds with the OpenTelemetry SDK. It exports with OTLP over HTTP. |
  | ConfigMap `shuttle-app` | The Python file `app.py`. The function `plot_course` uses only the API. The function `configure_sdk` installs the SDK. |
  | Deployment `collector` | An OpenTelemetry Collector. Its `debug` exporter prints everything it receives to its log. |
  | Service `collector` | Port 4317 for gRPC and port 4318 for HTTP. |

- The `shuttle` pod installs `opentelemetry-sdk` and `opentelemetry-exporter-otlp-proto-http` at version 1.45.2 with `pip` when it starts. Every restart takes a minute or more. Use `kubectl -n starfleet rollout status deploy/shuttle --timeout=300s` after each change.

## Helpers

Paste these once in each new terminal. `pipeline` prints the start-up line of the application, which names the provider and tracer classes. `received` prints the lines of the last minute of Collector output that match a word.

```sh
pipeline() {
  kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
}
received() {
  kubectl -n starfleet logs deploy/collector --since=60s | grep "$1"
}
```

Use them like this: `pipeline`, `received starfleet.navigation`, `received service.name`.

## Practice tasks

- Set `SHUTTLE_CONFIGURE_SDK=false` with `kubectl -n starfleet set env deploy/shuttle SHUTTLE_CONFIGURE_SDK=false`, wait for the rollout and run `pipeline`. Name the class of the tracer and explain why the Collector receives nothing.
- Set `SHUTTLE_CONFIGURE_SDK=true` and `OTEL_SDK_DISABLED=true`. Compare the tracer class with the previous case and explain the difference in one sentence.
- Remove `OTEL_SDK_DISABLED` with `OTEL_SDK_DISABLED-` and confirm that data returns.
- Run `kubectl -n starfleet exec deploy/shuttle -- pip show opentelemetry-sdk opentelemetry-api` and write down which package requires which.
- Find the value of `telemetry.sdk.version` in the Collector log and explain why it differs from the version of the Collector image.
