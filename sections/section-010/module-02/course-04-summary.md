---
draft: true
exam_objectives:
  - Data Model
---
# Summary

Attributes are typed key-value pairs on resources, scopes, spans, events, links, data points and log records. The value is a string, a boolean, an integer, a double, a byte array or an array of these. Limits can drop data silently. On metrics, each combination of attribute values is its own time series, so unbounded values such as order identifiers belong on spans and logs. A unit is part of the metric identity, and the SDK never checks that the recorded number matches it. Times are UTC nanoseconds from the producer's clock, and a log record keeps both the time of the event and the time of observation.

A metric instrument becomes a data type through its aggregation. Counters give monotonic sums, up-down counters give non-monotonic sums, gauges give the last value, and histograms give counts, a sum and buckets. Temporality says what time range a point covers. A cumulative point covers everything since a fixed start time, and a delta point covers only the last interval. The exporter preference `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` chooses `cumulative`, `delta` or `lowmemory`, and the delta setting still keeps up-down counters cumulative.

An exemplar is a sample measurement with a trace ID and a span ID attached to a data point. The exemplar filter, `OTEL_METRICS_EXEMPLAR_FILTER`, decides which measurements may become exemplars, and the reservoir keeps a few of them for each export. Exemplars do not change metric values. Semantic conventions give shared names, types and units to attributes and metrics, and a schema URL tells a consumer which version of the names the data uses.

Key facts:

- The `trace_based` filter needs an active, sampled span at the time of the measurement.
- A lost delta point loses data, and a lost cumulative point only loses resolution.
- Old and new attribute names for the same fact are different attributes.
- The metric descriptor description is not part of the metric identity; the name, unit and type are.
- A metric data point has no trace ID of its own. Only an exemplar links it to a trace.

<!-- astrona:playground:destroy -->
