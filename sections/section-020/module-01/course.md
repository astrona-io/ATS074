---
draft: true
exam_objectives:
  - Composability and Extension
---
# API And SDK Separation

This module explains why OpenTelemetry ships its instrumentation interface (the API) and its implementation (the SDK) as separate packages, what the API does when no SDK is installed, and how the stability rules of each package decide what you can depend on. The playground runs a real Python service that uses the OpenTelemetry SDK and a Collector, so every claim can be checked against a running system.

## Learning Goals

- Explain why a reusable library depends on the API package only and an application owns the SDK.
- Describe what the no-op API does when no SDK is configured, and what `OTEL_SDK_DISABLED` changes.
- Trace a call from instrumented code through a provider to an exporter and name the component that does each step.
- Explain how the stability and versioning rules apply to the API, the SDK, experimental signals and semantic conventions.

## Before You Start

You should know what a span, a metric and a log record are, and what a Kubernetes Deployment and ConfigMap are. The playground uses a kind cluster and `kubectl`. Every term is defined where it first appears.

## Reading Order

1. API And SDK As Separate Packages
2. The No-op API And Disabled SDKs
3. API Packages, Stability And Versioning
4. Summary

<!-- astrona:playground -->
