---
draft: true
exam_objectives:
- Composability and Extension
---
# Summary

API independence lets instrumented libraries expose telemetry without fixing an application's destination or collection policy. SDK providers create signal implementations, processors and readers shape the pipeline, and exporters deliver compatible data. Custom components extend supported contracts but inherit lifecycle, performance and error-handling responsibilities. A compatible type or package import is not evidence that every component agrees on signal, protocol or aggregation semantics.
