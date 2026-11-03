---
draft: true
exam_objectives:
  - Data Model
---
# Resources, Instrumentation Scope And Signal Identity

This module explains how OpenTelemetry says who produced a piece of telemetry. A resource describes the entity that produced it, an instrumentation scope describes the code that recorded it, and each signal carries its own identity fields. You read all three in the output of an OpenTelemetry Collector and then fix a wrong resource in a running service.

## Learning Goals

- Explain what a resource is, where its attributes come from and how `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES` combine.
- Decide whether an attribute belongs on the resource, on the instrumentation scope or on a single span, metric data point or log record.
- Read the identity fields of a span, a metric stream and a log record: trace ID, span ID, parent span ID, span kind, status, scope name and version.
- Correct a resource that has no service name and carries a per-request attribute, and prove the change in the Collector output.

## Before You Start

You should know what a Deployment, an environment variable and a pod log are. The hands-on steps use a playground with a kind cluster, an OpenTelemetry Collector and a small Python service built on the OpenTelemetry SDK. Technical terms are defined where they first appear.

## Reading Order

1. Resources And Service Identity
2. Instrumentation Scope And Signal Envelopes
3. Identity Of Spans, Metric Streams And Log Records
4. Summary

<!-- astrona:playground -->
