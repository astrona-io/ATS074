---
draft: true
exam_objectives:
  - Composability and Extension
---
# Samplers, Propagators And Custom Extensions

Processors and exporters move data, but two other SDK components decide what exists and how it connects. The sampler decides which traces are recorded at all. The propagator decides how trace context travels from one service to the next. Both can be replaced, and so can the processors and exporters, which raises a practical question: what must a custom component promise so that it does not damage the application it observes?

## Samplers

A **sampler** is a component that the tracer calls when a span starts. It receives the parent context, the trace identifier, the span name, the span kind, the initial attributes and the links. It returns a **sampling result** with one of three decisions: `DROP`, `RECORD_ONLY` or `RECORD_AND_SAMPLE`. It may also return extra attributes to add to the span.

The decision has two effects. With `DROP`, the span is not recorded, so no processor sees `on_end` with data and nothing is exported. With `RECORD_AND_SAMPLE`, the span is recorded and its trace flags carry the sampled bit, which tells downstream services to record their spans too. `RECORD_ONLY` records the span for local use, such as span-derived metrics, but does not mark it as sampled, so it is not exported by the standard processors.

The specification defines these built-in samplers. Each has a name that `OTEL_TRACES_SAMPLER` accepts:

- `always_on` and `always_off`: record every span, or none.
- `traceidratio`: keep a fixed fraction of traces, chosen from the trace identifier. `OTEL_TRACES_SAMPLER_ARG` holds the fraction, for example `0.25`.
- `parentbased_always_on`, `parentbased_always_off` and `parentbased_traceidratio`: follow the sampling decision of the parent span, and use the named sampler only for spans without a parent.

The default is `parentbased_always_on`. A **parent-based** sampler is a composite: it holds one sampler for root spans and one each for the four parent cases (remote parent sampled, remote parent not sampled, local parent sampled and local parent not sampled). Following the parent keeps traces whole. Without it, two services with `traceidratio` would each keep a different quarter of the requests, and most traces would be partial.

This is **head sampling**: the decision is made when the trace starts, before anything is known about its duration or errors. Choosing traces by what happened, such as keeping all slow or failed traces, is **tail sampling**, and it happens in the Collector, which sees the complete trace.

## Propagators

A **propagator** is a component that writes the current context into the headers of an outgoing request (`inject`) and reads it from an incoming request (`extract`). It works on a carrier, such as a dictionary of HTTP headers, through a getter and a setter. The default propagators, `tracecontext` and `baggage`, write the W3C `traceparent` header and the `baggage` header. `OTEL_PROPAGATORS` takes a comma-separated list, and the value `none` removes all propagators.

Other formats, such as `b3`, `jaeger` and `xray`, exist for interoperability with older systems, and each needs its own propagator package. If a name in `OTEL_PROPAGATORS` is not installed, the Python SDK raises an error when the propagation module loads, and the process fails at start-up.

The `plot_course` function injects the current context into an empty dictionary and returns it, and the application prints the sorted keys of that dictionary on every loop. With the default propagators the line shows `['traceparent']`.

## The contracts of custom components

Each component has a small interface, and a custom component must keep the promises behind it.

- A **processor** implements `on_start`, `on_end`, `shutdown` and `force_flush`. In `on_start` the span is writable, so this is the place to add attributes. In `on_end` the span is read-only. `on_start` and `on_end` run on the application thread, so they must be fast and must not raise.
- A **sampler** implements `should_sample` and `get_description`. It runs on the application thread for every span, so it must be deterministic and cheap. It must not call a remote service.
- An **exporter** implements `export(batch)` and `shutdown`. It returns a result and never raises into the processor. It has its own timeout, and it must not call an instrumented client without a guard, because export calls would create spans that need exporting.
- A **propagator** implements `inject`, `extract` and `fields`. It must ignore a malformed header and return the unchanged context, because a bad request from outside must not crash the service.

A custom processor looks like this in Python. It is the class the `shuttle` application builds when `SHUTTLE_SPAN_PROCESSORS` contains `crew-tag`:

```python
class CrewTagProcessor(SpanProcessor):
    def on_start(self, span, parent_context=None):
        span.set_attribute("starfleet.crew.size", 4)
    def on_end(self, span):
        pass
    def shutdown(self):
        pass
    def force_flush(self, timeout_millis=30000):
        return True
```

The class adds one attribute when a span starts and does no other work. It has no queue, no network call and no state.

## Enabling the custom processor

The next step resets the playground timer, adds the custom processor in front of the batch processor and waits for the new pod.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_SPAN_PROCESSORS=crew-tag,batch
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

The start-up line of the application lists the processors, and the Collector shows the attribute on the spans that arrive after the restart:

```sh
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
kubectl -n starfleet logs deploy/collector --since=40s | grep -m 3 "starfleet.crew.size"
```

The attribute `starfleet.crew.size` appears with the integer value 4. The processor changed the data without any change in the library function. A processor that mutates spans must do it in `on_start`, because the span that `on_end` receives is read-only, and the batch processor in the chain exports the same span object later.

## Changing the sampler and the propagator

Replace the sampler with a ratio sampler and read its description in the start-up line:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_TRACES_SAMPLER=traceidratio OTEL_TRACES_SAMPLER_ARG=0.25
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
```

The line now contains `sampler=TraceIdRatioBased{0.25}`, and roughly one trace in four reaches the Collector. Metrics are not affected, because the sampler only governs spans. Now switch the propagator off and look at the lines the application prints:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_TRACES_SAMPLER=parentbased_always_on OTEL_TRACES_SAMPLER_ARG- OTEL_PROPAGATORS=none
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
kubectl -n starfleet logs deploy/shuttle --tail=5
```

With `none`, the injected headers list is empty, so a downstream service would start a new trace. Set `OTEL_PROPAGATORS-` to remove the variable and return to the default before you continue.

## Failure cases of extensions

A processor that calls a remote service in `on_end` turns a slow destination into a slow request. A custom exporter that returns success for rejected data hides the loss, and one that retries without a limit grows memory. A sampler that reads a file on every span adds disk latency to every request. A custom exporter that logs its own failures through a logger bridged to the same exporter creates a loop of failure reports.

The safe design is the same in every case: bounded work, a bounded queue, no exceptions into the application, and failures reported by a path that does not use the failing component.

## What you know now

You can describe what a sampler decides and when, why parent-based samplers keep traces whole, what a propagator writes, and what each custom component must promise. You also changed a processor, a sampler and a propagator through configuration alone. The remaining skill is applying this to a system where several of these settings are wrong at once.

## Common pitfalls

> [!WARNING]
> Do not sample with `traceidratio` alone in a multi-service system, because each service then keeps a different set of traces: use a parent-based sampler. Do not mutate a span in `on_end`, where it is read-only. Do not set `OTEL_PROPAGATORS` to a name whose package is not installed, because the Python process fails at start-up. A custom component that blocks, raises or reports through itself harms the application it observes.
