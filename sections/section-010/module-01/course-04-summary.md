---
draft: true
exam_objectives:
  - Data Model
---
# Summary

Telemetry in OpenTelemetry has three levels of identity. The resource describes the producer: the service, its namespace, version, instance and environment. The SDK builds it once at startup from defaults, detectors, `OTEL_RESOURCE_ATTRIBUTES` and `OTEL_SERVICE_NAME`, and it stays the same until the process restarts. Without a service name the data arrives as `unknown_service`, and a value that changes with every request does not belong on the resource.

The instrumentation scope describes the code that recorded the data. It has a name, a version and optionally a schema URL and attributes. One resource can hold several scopes, and the same scope name can appear for traces, metrics and logs. OTLP sends the data as a resource entry, with scope entries inside it, with the signal items inside those. The Collector can change the resource of a whole batch without touching each item.

Each signal identifies its items in its own way. A span has a trace ID, a span ID and a parent span ID, a kind, a status, events and links. A parent-child relation is only the match between a parent span ID and a span ID in one trace. A metric stream is identified by the resource, the scope, the name, the unit, the type and the attributes together, and a data point has no trace ID. A log record has a time, a severity, a body and optional trace and span identifiers that the SDK copies from the active span.

Key facts:

- `OTEL_SERVICE_NAME` wins over `service.name` in `OTEL_RESOURCE_ATTRIBUTES`.
- A change to the resource needs a new process, so a Deployment needs a new rollout.
- A link between spans is not a parent relation.
- A log record connects to a trace only when it was written with the span context active.
- A span name describes a class of operations; a specific value goes in an attribute.

<!-- astrona:playground:destroy -->
