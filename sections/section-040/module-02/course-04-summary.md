---
draft: true
exam_objectives:
- Signals (Tracing, Metric, Log)
---
# Summary

The OpenTelemetry API defines how code records metrics, and the SDK does the work. Application code asks a `MeterProvider` for a `Meter` and creates instruments from it. Without an SDK the API does nothing. The SDK owns the aggregation, the views, the metric reader and the exporter, and it describes the process with a resource such as `service.name`.

Each instrument kind has a meaning. A counter only goes up, an up-down counter goes up and down, a histogram records the spread of values, and a gauge keeps the latest value. The observable (asynchronous) instruments do not record at the moment of an event. The SDK calls a callback once for every collection and the callback reports the current value. The meaning of the instrument decides its default aggregation: a sum, a last value or a histogram.

Temporality says what a sum or histogram data point covers. Cumulative data points cover the time since the start of the stream. Delta data points cover only the time since the previous export. The preference `cumulative`, `delta` or `lowmemory` sets this for the OTLP exporter, and up-down counters stay cumulative in the delta preference. Gauges have no temporality.

Views change the stream that leaves the SDK without changing the code that records. A view selects instruments and can keep only some attributes, change the bucket boundaries, rename the metric or drop it. The periodic reader collects and exports once for every interval, and a gauge can miss a peak between two exports. Cardinality is the number of distinct attribute sets of a metric. An unbounded value such as a request identifier creates a new series for every request, so the attribute must be removed or replaced by a bounded value. An exemplar ties one recorded value to a trace and span, and the exemplar filter decides which measurements may become exemplars.

Key facts:

- Counter and histogram follow the temporality preference. An up-down counter stays cumulative with `delta`.
- Views are read when the provider is created, so a change needs a restart of the process.
- The default histogram boundaries suit values in milliseconds, so a duration in seconds needs a view or an advisory.
- A metric is for aggregates. Details of a single request belong in traces and logs.

<!-- astrona:playground:destroy -->
