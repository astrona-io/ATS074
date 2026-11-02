---
draft: true
exam_objectives:
- SDK Pipelines
---
# Summary

SDK pipelines turn API observations into exportable signal data. Trace processors, metric readers and log processors use different contracts. Sampling selects trace evidence, while metric aggregation combines measurements with defined temporal meaning. Batching reduces export overhead but introduces queues and delay. Flush and shutdown are bounded lifecycle operations, so configured delivery still needs failure visibility and cannot be treated as an unconditional guarantee.
