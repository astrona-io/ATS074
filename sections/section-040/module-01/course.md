---
draft: true
exam_objectives:
- Signals (Tracing, Metric, Log)
---
# Tracing With The OpenTelemetry API And SDK

A trace records the path of one request through the code that handles it. This module explains how the OpenTelemetry API and SDK for Python create that record: the tracer provider, the tracer, the span and everything a span carries, how spans form a tree, and how span processors, samplers and exporters decide which spans leave the process. You read the result in the log of an OpenTelemetry Collector.

## Learning Goals

- Explain the split between the OpenTelemetry API, which application code calls, and the SDK, which implements it, and name what a `TracerProvider`, a `Resource` and a tracer each do.
- Describe the anatomy of a span: trace ID, span ID, parent span ID, name, kind, start and end time, status, attributes, events and links.
- Explain how the current context makes one span the parent of the next, and why a root span starts a new trace.
- Predict what a sampler, a span processor and an exporter do to a span, and what is lost when a trace is not sampled or the queue is full.
- Instrument a small Python function with the tracing API and read the resulting spans in the Collector log.

## Before You Start

You should know what a process, a container and an environment variable are, and you should be able to read a few lines of Python. The hands-on steps use a playground with a kind cluster, `kubectl` and a Python application that is already instrumented. Technical terms are defined where they first appear.

## Reading Order

1. The tracer provider, the resource and the tracer
2. Span anatomy and parent-child structure
3. Processors, samplers and exporters
4. Summary

<!-- astrona:playground -->
