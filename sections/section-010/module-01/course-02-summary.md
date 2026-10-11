---
draft: true
exam_objectives:
- Data Model
---
# Summary

OpenTelemetry groups observations under resource and instrumentation-scope identity while preserving signal-specific models. Spans describe timed operations, metric points carry aggregation and temporal meaning, and log records describe events with optional correlation. Attribute location, units and timestamps influence interpretation. A common transport does not flatten these distinctions or guarantee that a backend will preserve every field with identical semantics.
