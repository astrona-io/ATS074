---
draft: true
exam_objectives:
- Data Model
---
# Data Model

This section explains the data that OpenTelemetry produces and how that data identifies who made it. It covers the resource that describes the producing service, the instrumentation scope that describes the recording code, and the identity fields of spans, metric streams and log records. It then covers attributes, units, timestamps, the kinds of metric data point, aggregation temporality, exemplars and semantic conventions.

The first module teaches identity and structure. The second module teaches the contents of the data items and the metric model. Both modules use a playground with an OpenTelemetry Collector and a small service built on the OpenTelemetry Python SDK, and both have a graded lab. A capstone lab combines the two, and a quiz closes the section.

## Learning Outcomes

- Distinguish resource, instrumentation scope and observation attributes, and place a given attribute at the right level.
- Explain how `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES` combine into a resource, and correct a wrong resource in a running service.
- Explain span, metric stream and log record identity, including trace ID, span ID, parent span ID, span kind and status.
- Reason about attribute types and limits, metric cardinality, units and UTC timestamps.
- Tell sums, gauges and histograms apart, and explain monotonicity and cumulative and delta temporality.
- Explain what an exemplar is, configure the exemplar filter and the temporality preference, and read the result in the Collector output.
- Explain the purpose of semantic conventions and schema URLs.
