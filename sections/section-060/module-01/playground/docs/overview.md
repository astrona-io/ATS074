# Overview: Context, Boundaries And W3C Trace Context (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Read logs, change environment variables, read the logs again, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. Start-up takes a few minutes, because each Python pod runs `pip install` for the OpenTelemetry SDK.
- Three Deployments in the `starfleet` namespace:

  | Deployment | What it is |
  | --- | --- |
  | `shuttle` | Python service. Every 5 seconds it starts a `shuttle.dispatch` span, injects the context into HTTP headers and calls the `probe`. A worker thread starts a `shuttle.audit` span |
  | `probe` | Python service on port 8080. It extracts the context from the request headers and starts a `probe.scan` span |
  | `collector` | OpenTelemetry Collector that receives OTLP/HTTP and prints every span with the `debug` exporter |

- The `shuttle` runs with `SHUTTLE_ATTACH_CONTEXT=false`, so the worker thread does not receive the active context, and it sets the baggage entry `mission=survey`. No `OTEL_PROPAGATORS` variable is set, so both services use the default `tracecontext,baggage`.
- Both Python services print `PROPAGATION` lines with `trace_id`, `span_id` and `parent_span_id` (`none` for a root span). The `probe` line also has `remote`, the `traceparent` header it received and the baggage it received.

## Helper

Paste this once in each new terminal. It prints the recent `PROPAGATION` lines of `shuttle` or `probe`.

```sh
propagation_lines() {
  kubectl -n starfleet logs "deploy/$1" --tail=30 | grep '^PROPAGATION'
}
```

Use it like this: `propagation_lines shuttle`, `propagation_lines probe`. The collector logs are `kubectl -n starfleet logs deploy/collector`.

## Practice tasks

- Find a `role=worker` line in the `shuttle` log. Note that `parent_span_id=none`, then explain why a new thread starts without the active context.
- Set `SHUTTLE_ATTACH_CONTEXT=true` with `kubectl -n starfleet set env deployment/shuttle SHUTTLE_ATTACH_CONTEXT=true`, wait for the new pod, and compare the worker line with the `role=client` line of the same iteration.
- Take one `traceparent` value from a `probe` line and split it at the dashes into version, trace ID, parent ID and flags. Find the `shuttle` client line whose `span_id` equals the parent ID.
- Check that the `trace_id` of a `probe` line equals the `trace_id` of the matching `shuttle` client line, and that the `probe` span has `remote=true`.
- Look for `shuttle.dispatch` and `probe.scan` in the collector logs and compare their trace IDs.
