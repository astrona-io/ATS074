---
draft: true
exam_objectives:
  - Context Propagation
---
# Context, Boundaries And W3C Trace Context

This module explains how one trace stays connected inside a service and between two services. It starts with the Context object and the active context, follows the context across threads and asynchronous work, and ends with the W3C `traceparent` and `tracestate` headers that carry it over HTTP. You read real span identifiers from the logs of two running services.

## Learning Goals

- Explain what a Context is, how the active context is stored, and how `attach` and `detach` change it.
- Explain how a new span chooses its parent and why a missing context creates a root span.
- Carry a Context across a thread boundary and explain which boundaries do not carry it automatically.
- Read a `traceparent` header field by field and match its parent ID to the span that sent it.
- Describe the role of `tracestate` and of the sampled flag.

## Before You Start

You should know what a trace, a span and a span ID are, and how to read a pod log with `kubectl`. The hands-on parts use a playground with a kind cluster, a Python service called `shuttle` that calls a Python service called `probe`, and an OpenTelemetry Collector. Technical terms are defined where they first appear.

## Reading Order

1. The Context Object And The Active Context
2. Keeping Context Across Threads And Asynchronous Work
3. The W3C traceparent And tracestate Headers
4. Summary

<!-- astrona:playground -->
