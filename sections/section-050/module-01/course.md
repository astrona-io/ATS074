---
draft: true
exam_objectives:
  - SDK Pipelines
---
# The Trace Pipeline

This module follows one span through the OpenTelemetry SDK, from the moment application code starts it to the moment an exporter sends it to a destination. The path has four stages: a provider that creates tracers, a sampler that decides whether the span is recorded, a span processor that receives the finished span, and an exporter that sends it. Each stage can delay, change or drop the span, and the module shows where.

## Learning Goals

- Name the components of the trace pipeline and say which one does each step: provider, sampler, span processor and exporter.
- Explain the sampling decisions (drop, record only, record and sample) and choose between `always_on`, `always_off`, `traceidratio` and the parent-based samplers.
- Compare the simple and the batching span processor, and set the batch queue with the `OTEL_BSP_*` variables.
- Explain what force flush and shutdown do, why a pod that is killed can lose spans, and how to size the queue and the grace period.

## Before You Start

You should know what a span, a trace and a trace ID are, and what OTLP (the OpenTelemetry Protocol) is. The hands-on parts use a playground with a kind cluster, `kubectl` and an OpenTelemetry Collector that prints what it receives. A small Python service, `shuttle`, uses the real OpenTelemetry Python SDK and is configured only with environment variables. Technical terms are defined where they first appear.

## Reading Order

1. Providers, Samplers And The Span Path
2. Span Processors And Exporters
3. Flush And Shutdown
4. Summary

<!-- astrona:playground -->
