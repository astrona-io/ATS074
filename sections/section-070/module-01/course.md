---
draft: true
exam_objectives:
  - Agents
---
# Language Instrumentation Agents

This module explains what an instrumentation agent is, how the Python agent `opentelemetry-instrument` attaches telemetry to an application that has no OpenTelemetry code, how you configure it, and where its coverage ends. The hands-on work uses a small Flask application that already runs under the agent.

## Learning Goals

- Explain what an instrumentation agent does inside an application process and which component does each step.
- Install and start the Python agent with `opentelemetry-distro`, `opentelemetry-bootstrap` and `opentelemetry-instrument`.
- Configure the agent with `OTEL_*` environment variables: service name, resource attributes, exporters, disabled instrumentations and excluded URLs.
- Name what automatic instrumentation can and cannot record, and decide when manual instrumentation is also needed.

## Before You Start

You should know what a span, a metric and a log record are, and what a Kubernetes Deployment and a ConfigMap are. The hands-on part uses a playground with a kind cluster, `kubectl` and `jq`. Technical terms are defined where they first appear.

## Reading Order

1. What An Instrumentation Agent Does
2. Configuring The Agent With Environment Variables
3. What The Agent Covers And What It Cannot
4. Summary

<!-- astrona:playground -->
