---
draft: true
exam_objectives:
- Context Propagation
---
# Summary

Context propagation carries execution-scoped relationships across local and remote boundaries. A sender injects supported context into a carrier, and a receiver extracts it before creating related work. Trace context supports causal identity, while baggage carries selected contextual values and is not automatically attached to every observation. Propagated input is untrusted data, so it must not become authorization or an unrestricted path for confidential values.
