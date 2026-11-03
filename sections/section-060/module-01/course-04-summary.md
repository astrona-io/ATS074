---
draft: true
exam_objectives:
  - Context Propagation
---
# Summary

A Context is an immutable mapping that carries values for one unit of work, mainly the current span and the baggage. The active context is the Context stored for the current thread or task. Code changes it with attach and detach, and a new span reads its parent from the Context it is created in. When no span is in that Context, the span is a root span with a new trace ID.

The active context does not follow work to a new thread or to a thread-pool task. Asynchronous tasks in an event loop copy it, but raw threads start empty. The code that hands off the work must capture the Context, pass it as an argument, attach it in the worker and detach it in a `finally` block. A lost context is not an error. The request succeeds and the trace splits, so the relationship is found by reading the parent span IDs.

Between processes, the identity of the sending span travels in the W3C `traceparent` header: version, a 32-character trace ID, a 16-character parent ID that names the sender, and trace flags whose first bit is the sampled flag. The `tracestate` header carries optional vendor data next to it. A receiver that finds a missing or invalid header starts a new trace instead of failing.

Key facts:

- `traceparent` has four fields, `00-<32 hex>-<16 hex>-<2 hex>`.
- `parent-id` is the span ID of the sender.
- Flag `01` means sampled, `00` means not sampled.
- Pool threads and new threads need an explicit attach.

<!-- astrona:playground:destroy -->
