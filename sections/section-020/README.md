---
draft: true
exam_objectives:
  - Composability and Extension
---
# Composability and Extension

OpenTelemetry splits instrumentation from implementation. Libraries call the API, and only the application installs an SDK that decides where telemetry goes. This section explains that split and the parts of the SDK you can swap or extend. You work against a real Python service and a Collector that run in a local cluster.

## Modules

1. API And SDK Separation: the two packages, what the API does without an SDK, `OTEL_SDK_DISABLED`, and the stability and versioning rules of each package.
2. SDK Components And Extension Contracts: providers, resources and instrumentation scope, span processors, metric readers, exporters, samplers, propagators, and the rules a custom component must follow.

Each module has a playground for experiments and one graded lab. The capstone combines both modules in one broken service.

## Learning Outcomes

After this section you can:

- Explain why library code depends on the API and the application owns the SDK, and name the Python packages for each.
- Predict what happens to spans, metrics and log records when no SDK is registered or when `OTEL_SDK_DISABLED` is `true`.
- Read the version of an API or SDK package and say which stability guarantees apply.
- Identify the provider, resource, processor, reader, exporter, sampler and propagator in a running pipeline and change each with environment variables.
- Choose between the simple and the batch span processor, and between head sampling options such as `traceidratio` and `parentbased_*`.
- State the rules a custom processor, sampler or propagator must follow: bounded work, no exceptions into the application, no feedback loops.
- Diagnose a service with a silent or partial pipeline by reading pod logs and Collector output, and repair it by changing configuration only.
