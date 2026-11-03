# Overview: Propagators, Baggage And Broken Propagation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Read logs, change environment variables, read the logs again, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it. Start-up takes a few minutes, because each Python pod runs `pip install` for the OpenTelemetry SDK.
- Three Deployments in the `starfleet` namespace:

  | Deployment | What it is |
  | --- | --- |
  | `shuttle` | Python service. Every 5 seconds it starts a `shuttle.dispatch` span, injects the context into HTTP headers and calls the `probe`. A worker thread starts a `shuttle.audit` span |
  | `probe` | Python service on port 8080. It extracts the context from the request headers and starts a `probe.scan` span |
  | `collector` | OpenTelemetry Collector that receives OTLP/HTTP and prints every span with the `debug` exporter |

- The `shuttle` sets the baggage entries `mission=survey` and `session-token=demo-not-a-real-secret` and attaches the context in its worker thread. No `OTEL_PROPAGATORS` variable is set, so both services use the default `tracecontext,baggage`. The `probe` copies no baggage keys to span attributes (`PROBE_BAGGAGE_ATTRIBUTES` is empty).
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

- Read a `shuttle` client line. It shows the `traceparent` and `baggage` headers that `propagate.inject` wrote, including the `session-token` entry. Then read the `probe` line and find the same entries.
- Set `OTEL_PROPAGATORS=baggage` on the `probe` with `kubectl -n starfleet set env deployment/probe OTEL_PROPAGATORS=baggage`. Read the new `probe` lines: `remote=false` and `parent_span_id=none`, yet the request still succeeds.
- Set `OTEL_PROPAGATORS=tracecontext` on the `probe` instead. The trace continues, and the `baggage` field of the `probe` line is `none`.
- Set `OTEL_PROPAGATORS=none` on the `shuttle` and compare the headers in its client line.
- Set `PROBE_BAGGAGE_ATTRIBUTES=mission` on the `probe`, then search the collector logs for `baggage.mission`. Check that nothing named `baggage.session-token` appears.
