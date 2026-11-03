---
draft: true
exam_objectives:
- Signals (Tracing, Metric, Log)
---
# Summary

OpenTelemetry splits tracing into an API and an SDK. Application and library code calls the API, which does nothing until an SDK is registered. The SDK provides the `TracerProvider`, which holds the resource, the sampler and the span processors. The resource describes the service that produces the telemetry, and its `service.name` comes from `OTEL_SERVICE_NAME` or `OTEL_RESOURCE_ATTRIBUTES`. A tracer names the instrumentation scope that creates spans.

A span is one timed operation. It carries a trace ID shared by the whole trace, its own span ID, the span ID of its parent, a name, a kind, start and end times, a status, attributes, events and links. The parent comes from the current context: the span that is active when a new span starts becomes its parent, and a span with no active parent starts a new trace. Status belongs to one span, a failed child does not mark its parent, and a link relates two spans without making either a parent of the other. An exception that leaves a span sets the error status and adds an exception event unless the code switches that off.

The sampler decides once, when a span is created, whether to keep it. A parent-based sampler lets a trace stay whole, and a ratio of zero keeps nothing. The batch span processor queues finished spans, exports them on a schedule and drops them when the queue is full. The exporter sends the spans over OTLP to the endpoint in the environment. Any of these stages can remove spans without an error in the application, so a missing span is checked stage by stage: sampling, processing, exporting and the Collector.

Key facts:

- The API records nothing without a registered SDK.
- `OTEL_SERVICE_NAME` overrides `service.name` in `OTEL_RESOURCE_ATTRIBUTES`.
- The default sampler is `parentbased_always_on`.
- A span with an empty parent ID is the root of its trace.
- Only ended spans are exported.
- Status values are `Unset`, `Ok` and `Error`.

<!-- astrona:playground:destroy -->
