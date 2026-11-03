---
draft: true
exam_objectives:
- Configuration
---
# Configuration

This section covers how an OpenTelemetry SDK is configured. The SDK is the part of the OpenTelemetry library that runs inside the application and records and exports telemetry. It does not configure itself from nothing: the application code, the standard `OTEL_*` environment variables and, in newer SDKs, a declarative configuration file all feed the same objects.

The first module follows an SDK from start-up: which objects the initialization code builds, how the SDK reads and parses environment variables, and how it builds the resource, the set of attributes that identifies the service. The second module covers the OTLP exporter (endpoint, protocol, headers, timeout), the sampler, the batching and export intervals, the declarative configuration file and the failure modes of a wrong configuration. The hands-on work runs a small Python service that uses the real OpenTelemetry SDK and sends telemetry to an OpenTelemetry Collector. You change its configuration and read the effect in the Collector output.

## Learning Outcomes

- Name the objects that SDK initialization creates and explain why initialization must run before the instrumented work.
- Predict how the SDK parses boolean, numeric, enumerated and list values of `OTEL_*` environment variables, including invalid values.
- Build a correct resource with `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES` and explain which source wins when two sources set the same attribute.
- Choose the OTLP endpoint, protocol, headers and timeout for a Collector and explain when the SDK appends the signal path.
- Select a sampler with `OTEL_TRACES_SAMPLER` and `OTEL_TRACES_SAMPLER_ARG` and tune batch and metric export intervals.
- Explain what a declarative configuration file changes and diagnose a missing signal from the configuration layer that failed.
