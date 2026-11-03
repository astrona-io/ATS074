---
draft: true
exam_objectives:
- Signals (Tracing, Metric, Log)
---
# Signals (Tracing, Metric, Log)

OpenTelemetry describes a running system with three signals. Traces follow one request through spans. Metrics aggregate measurements into time series. Logs record individual events. Each signal has its own API objects and its own SDK pipeline, but the three pipelines share one idea: a provider holds the configuration, a processor or reader moves the data on, and an exporter sends it out. This section builds the three pipelines in the Python SDK, runs them against an OpenTelemetry Collector in a kind cluster, and then joins the signals by trace context and by one shared Resource.

The section has three modules and a capstone lab. The first module covers tracing: the tracer provider, the anatomy and the parent-child structure of spans, samplers, span processors and exporters. The second module covers metrics: meters and instruments, aggregation, temporality, views, metric readers, cardinality and exemplars. The third module covers logs: the log record, the logs SDK pipeline, the bridge from the Python standard `logging` module, trace correlation, events, retention and sensitive data. The capstone repairs a service whose three signals are all misconfigured. A quiz closes the section.

## Learning Outcomes

- Explain the identity, timing, status and parent-child structure of a span.
- Describe how a sampler decides at span creation, and how a span processor and an exporter move finished spans on.
- Choose a metric instrument for a measured quantity: counter, up-down counter, gauge or histogram.
- Distinguish cumulative from delta temporality, and explain what a view and a metric reader change.
- Predict the effect of a high-cardinality attribute on the number of time series.
- Name the fields of a log record and map severity text to the severity number bands.
- Describe the path of a log record through the `LoggerProvider`, the log record processors and the exporter.
- Explain when a log record carries a trace ID and a span ID, and why a dropped trace still leaves identifiers in log records.
- Explain why one Resource shared by the tracer, meter and logger providers gives all three signals the same service identity.
- Account for volume, retention and sensitive data in a logs pipeline, and remove sensitive attributes before export.
- Diagnose a service whose signals do not arrive, or do not join, by reading the Collector output and the environment variables of the service.
