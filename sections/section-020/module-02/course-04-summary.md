---
draft: true
exam_objectives:
  - Composability and Extension
---
# Summary

The SDK is a set of components with small, separate contracts. A provider creates the signal objects and owns the resource, the pipeline and the lifecycle. The resource describes the producing service and comes from the SDK, `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES`. The instrumentation scope describes the library that created the data. A short-lived process must flush or shut down its providers, because buffered data is lost when the process ends.

Between a finished span and the Collector, a processor decides when data moves and an exporter sends it. The simple span processor exports on the application thread, and the batch span processor queues spans and exports them on a timer, dropping spans when the queue is full. Metrics use readers and logs use log record processors, and each chain has its own timer and variables. An OTLP exporter needs a protocol and a port that match the receiver, and a failed export is logged but does not stop the application.

The sampler decides at span start whether a span is recorded, and a parent-based sampler follows the decision of the parent so traces stay whole. The propagator writes and reads context in request headers, and the value `none` turns it off. Custom processors, samplers, exporters and propagators plug in through these interfaces. They must do bounded work, never raise into the application and never report their own failures through the component that is failing.

- A provider owns the resource, the pipeline and the policy; a tracer adds the scope.
- A processor decides when, an exporter decides how, a reader collects metrics.
- `OTEL_BSP_*`, `OTEL_METRIC_EXPORT_INTERVAL` and `OTEL_BLRP_*` tune the three chains.
- Head sampling happens at span start; tail sampling happens in the Collector.
- Mutate a span in `on_start`, never in `on_end`.

<!-- astrona:playground:destroy -->
