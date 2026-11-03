# Overview: Language Instrumentation Agents (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a zero-code Python app and a Collector that prints what it receives, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the environment of the app, read the Collector log, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it. You need `jq` on your machine.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployment `collector` | OpenTelemetry Collector (contrib 0.164.0). Receives OTLP on 4317 (gRPC) and 4318 (HTTP). The `debug` exporter prints every span, metric and log record |
  | Deployment `scout` | A Flask app. Its ConfigMap `scout-app` holds `app.py` (no OpenTelemetry import) and `start.sh` (`pip install`, `opentelemetry-bootstrap -a install`, `opentelemetry-instrument python /app/app.py`) |
  | Deployment `drifter` | Calls `/relay` and `/dock` on `scout` every five seconds |

- `scout` is configured only by `OTEL_*` environment variables on its Deployment: service name, resource attributes, exporters, endpoint and protocol.
- The pod needs about two minutes after the start, because it installs its packages first.

## Helpers

Paste these once in each new terminal. `collector_log` prints the last minute of the Collector log. `scout_env` prints the `OTEL_*` variables of the `scout` container.

```sh
collector_log() {
  kubectl -n starfleet logs deploy/collector --since="${1:-60}s"
}
scout_env() {
  kubectl -n starfleet get deployment scout -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
}
```

## Practice tasks

- Run `collector_log | grep -E 'Name +:'` and list the span names. Decide which one comes from Flask and which one comes from the `requests` library.
- Run `kubectl -n starfleet exec deploy/scout -- pip list` and find the packages whose names start with `opentelemetry-instrumentation-`. Explain why `bootstrap` installed them.
- Set `OTEL_PYTHON_EXCLUDED_URLS=healthz` with `kubectl set env`, wait for the rollout and check that `GET /healthz` disappears.
- Set `OTEL_SERVICE_NAME=scout-v2` and find the new name in the resource block of the log.
- Set `OTEL_TRACES_EXPORTER=console` and look at the `scout` pod log instead of the Collector log. Set it back to `otlp`.
- Find the `/dock` handler in `app.py`. Decide which business facts (the berth, the wait time) the agent cannot see.
