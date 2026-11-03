---
draft: true
exam_objectives:
  - Context Propagation
---
# Context Propagation

This section explains how OpenTelemetry keeps the work of one request connected. It covers the Context object and the active context inside a process, the W3C `traceparent` and `tracestate` headers between processes, propagators and the `OTEL_PROPAGATORS` variable, baggage and its security limits, and the failure modes of broken propagation. Every module uses two Python services that call each other over HTTP and an OpenTelemetry Collector, so you read real span identifiers.

The section has two modules, a capstone lab and a quiz. The first module follows the context from a function call to a worker thread to an HTTP request. The second module covers the propagators that write and read the headers, the baggage that travels with them, and a method for finding where a trace splits.

## Learning Outcomes

- Explain what a Context is, how the active context is stored, and how a new span chooses its parent.
- Carry a Context across a thread or asynchronous boundary and name the boundaries that do not carry it automatically.
- Read a `traceparent` header field by field and explain `tracestate` and the sampled flag.
- Explain inject and extract, the carrier with its setter and getter, and choose propagators with `OTEL_PROPAGATORS`.
- Distinguish trace context from baggage and from authorization, and name the security and size limits of baggage.
- Find the broken step in a split trace by comparing what the sender wrote with what the receiver got, and tell propagation faults from sampling decisions.
