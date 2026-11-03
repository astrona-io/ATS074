---
draft: true
exam_objectives:
  - Composability and Extension
---
# SDK Components And Extension Contracts

This module opens the OpenTelemetry SDK and names every component in the path from a finished span to the Collector: providers, resources, processors, metric readers, exporters, samplers and propagators. It also shows the contract each component must satisfy, so you can judge whether a custom component is safe. The playground runs a Python service with a custom span processor that you can switch on and off.

## Learning Goals

- Describe what a provider, a resource and an instrumentation scope each contribute to the data.
- Compare simple and batch span processors, periodic metric readers and log record processors, and tune them with the standard `OTEL_*` variables.
- Explain how a sampler decides, how a parent-based sampler follows its parent, and how a propagator carries context between services.
- State the contract of a custom processor, sampler, exporter or propagator and the failure cases it must avoid.

## Before You Start

You should know what a span, a metric, a log record and an environment variable are, and that the API and the SDK are separate layers. The hands-on steps use a kind cluster, `kubectl` and a Collector that prints what it receives. Terms are defined where they first appear.

## Reading Order

1. Providers, Resources And Instrumentation Scope
2. Processors, Readers And Exporters
3. Samplers, Propagators And Custom Extensions
4. Summary

<!-- astrona:playground -->
