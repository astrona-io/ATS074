---
draft: true
exam_objectives:
  - SDK Pipelines
---
# Metric And Log Pipelines

The metric and log pipelines of the OpenTelemetry SDK do not work like the trace pipeline. A metric is not sent once per measurement: the SDK combines measurements into aggregated streams and a reader exports them at a fixed interval. A log record is sent like a span, through a batching processor, but it comes from the logging library of the application and carries the trace context of the active span. This module explains both pipelines and the limits that decide how much data arrives.

## Learning Goals

- Name the components of the metric pipeline: meter provider, instrument, view, aggregation, metric reader and exporter.
- Use views to rename a metric stream, remove attributes, change histogram buckets or drop a stream.
- Explain the periodic export interval, cumulative and delta temporality, and what each means for a backend.
- Describe the log pipeline: logger provider, log record processor, exporter, and the link from a log record to the active span.
- Size the batching log processor and explain what happens to records when the queue is full or the process stops.

## Before You Start

You should know the difference between a counter, a histogram and a gauge, and what an attribute is. The hands-on parts use the same playground idea as the trace module: a kind cluster, `kubectl`, an OpenTelemetry Collector that prints what it receives and the Python service `shuttle`, which is configured with environment variables.

## Reading Order

1. Meter Providers, Views And Aggregation
2. Metric Readers And Temporality
3. Log Pipelines And Delivery Limits
4. Summary

<!-- astrona:playground -->
