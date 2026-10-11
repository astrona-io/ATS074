---
draft: true
exam_objectives:
- Signals (Tracing, Metric, Log)
---
# Summary

A trace connects spans that describe operations in one distributed request. Context propagation allows participating services to preserve that relationship, while span timing and attributes help locate expensive or failed work.

Missing instrumentation, sampling and propagation errors can leave an incomplete picture. Concurrent spans must be interpreted by their timing and relationships rather than summed blindly, and trace attributes need controlled cost and confidentiality.

Metric types describe different measurement contracts. Counters accumulate events, gauges represent changing state, and distributions preserve information about observed values such as duration.

Queries must respect those contracts and the selected population. Scraped samples are bounded observations, while labels determine identity and cost; a useful metric is a clear answer to an operational question rather than an arbitrary number with a dashboard.

Metrics describe numerical behavior across time, while logs and events preserve individual observations and their context. Structured identity and timestamps make records useful for correlating symptoms with activity.

Collection scope, sampling and retention limit the conclusions supported by a search. Protect sensitive fields and preserve enough context to investigate without treating every log line as a complete or trustworthy account.
