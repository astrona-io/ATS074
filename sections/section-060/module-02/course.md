---
draft: true
exam_objectives:
  - Context Propagation
---
# Propagators, Baggage And Broken Propagation

This module explains how a service injects and extracts context with a propagator, how the `OTEL_PROPAGATORS` environment variable chooses the header formats, what baggage carries and why it needs care, and how to find where propagation breaks. You work with two Python services that call each other over HTTP and an OpenTelemetry Collector that shows what arrives.

## Learning Goals

- Describe a propagator, a carrier, a setter and a getter, and say which component calls inject and extract.
- Choose and change propagators with `OTEL_PROPAGATORS` and explain what each standard value means.
- Explain what baggage is, what it does not do, and why it must not hold secrets or authorization data.
- Copy a baggage key to a span attribute with an allowlist.
- Diagnose a split trace by comparing what the sender wrote with what the receiver got, and recognize a sampling decision as a separate cause.

## Before You Start

You should know what a trace, a span, a span ID and the W3C `traceparent` header are, and how to read a pod log with `kubectl`. The hands-on parts use a playground with a kind cluster, a Python service called `shuttle` that calls a Python service called `probe`, and an OpenTelemetry Collector. Technical terms are defined where they first appear.

## Reading Order

1. Propagators: Inject, Extract And OTEL_PROPAGATORS
2. Baggage And Its Security Limits
3. Diagnosing Broken Propagation
4. Summary

<!-- astrona:playground -->
