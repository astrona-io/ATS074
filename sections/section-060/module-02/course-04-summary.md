---
draft: true
exam_objectives:
  - Context Propagation
---
# Summary

A propagator writes the values of a Context into a carrier on injection and reads them back on extraction. The carrier is the request headers or the message headers, and a setter and a getter hide its type. The global propagator is a composite built once at start from `OTEL_PROPAGATORS`, which defaults to `tracecontext,baggage`. The sender and the receiver choose their lists separately, so a trace continues only when they share a format. A name that is not installed can stop the process at start.

Baggage is a set of name-value pairs in the Context that the `baggage` propagator sends to every downstream service. It is not a span attribute unless code copies it, and it is not authorization. Because it travels in clear text across every boundary of the request, it must not hold secrets, credentials or personal data. An allowlist can copy selected low-cardinality keys to span attributes, and the entry service can remove incoming pairs.

Broken propagation hides behind successful requests. The method is to read what the sender wrote, what the receiver got and what the receiver did with it, in that order. A sender that wrote nothing points to injection, a missing header at the receiver points to the transport, and a header that arrived but gave a root span points to extraction. A correct header with the flag `00` points to the sampler, not to propagation.

Key facts:

- `OTEL_PROPAGATORS` values: `tracecontext`, `baggage`, `b3`, `b3multi`, `jaeger`, `xray`, `ottrace`, `none`.
- The `none` value turns propagation off.
- Baggage is never automatically attached to spans, metrics or logs.
- An incoming trace ID is for correlation and is never proof of identity.

<!-- astrona:playground:destroy -->
