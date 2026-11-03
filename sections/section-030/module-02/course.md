---
draft: true
exam_objectives:
- Configuration
---
# Exporter, Sampler And Declarative Configuration

This module covers the settings that decide whether recorded telemetry leaves the application: the OTLP exporter endpoint, protocol, headers and timeout, the sampler, and the batch and metric export intervals. It also explains the declarative configuration file and how to find the layer that failed when a signal is missing.

## Learning Goals

- Choose the OTLP endpoint and protocol for a Collector listener and explain when the SDK appends the signal path.
- Pass authentication headers without writing them into the Deployment.
- Select a sampler with `OTEL_TRACES_SAMPLER` and `OTEL_TRACES_SAMPLER_ARG` and predict its decisions.
- Tune the batch span processor and the metric reader, and explain what a declarative configuration file changes.
- Diagnose a missing signal by checking the sampler, the exporter and the Collector in order.

## Before You Start

You should know what an SDK pipeline is, how `OTEL_*` variables are parsed and what a resource is. The hands-on part uses a playground with a kind cluster, a Python service called `shuttle` and an OpenTelemetry Collector called `collector`. Technical terms are defined where they first appear.

## Reading Order

1. Configuring The OTLP Exporter
2. Sampling And Export Intervals
3. Declarative Configuration And Failure Modes
4. Summary

<!-- astrona:playground -->
- The endpoint, the protocol and the Collector listener must match.
- A signal-specific endpoint is used as written, and the general endpoint gets a signal path.
- A sampler that does not record leaves nothing for the exporter to send.
