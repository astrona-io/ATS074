---
draft: true
exam_objectives:
- Configuration
---
# SDK Initialization, Environment Variables And Resources

This module follows an OpenTelemetry SDK from process start. You see what the initialization code builds, how the SDK reads `OTEL_*` environment variables and how it assembles the resource that identifies the service. Every idea is tried on a running Python service that exports to an OpenTelemetry Collector.

## Learning Goals

- Name the providers, processors and exporters that initialization creates and the order in which the application must create them.
- Explain why the API does nothing until a provider is registered.
- Predict how the SDK parses boolean, numeric, enumerated and list values, and what it does with an invalid value.
- Explain how `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES` and code-defined attributes combine into one resource.

## Before You Start

You should know what a trace, a span and a metric are, what a Kubernetes Deployment and an environment variable are, and how to read pod logs with `kubectl`. The hands-on part uses a playground with a kind cluster, a Python service called `shuttle` and an OpenTelemetry Collector called `collector`. Technical terms are defined where they first appear.

## Reading Order

1. How SDK Initialization Builds The Pipeline
2. Reading OTEL Environment Variables
3. Building The Resource
4. Summary

<!-- astrona:playground -->
- Initialization creates providers, processors and exporters, and the application registers them before the work starts.
- The SDK parses environment variables by fixed rules and ignores values it cannot parse.
- `OTEL_SERVICE_NAME` wins over `service.name` in `OTEL_RESOURCE_ATTRIBUTES`.
