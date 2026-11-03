---
draft: true
exam_objectives:
  - SDK Pipelines
---
# SDK Pipelines

The OpenTelemetry SDK is the part of the library that sits between the instrumentation calls of an application and the exporter that sends data to a destination. This section follows each signal through that path. A span passes a sampler, a span processor and an exporter. A metric passes a view, an aggregation and a metric reader. A log record passes a bridge, a log record processor and an exporter. For every stage the section explains what the stage does, which settings control it and how it can lose or delay data.

The first module covers the trace pipeline: providers, samplers, the simple and the batching span processor, exporters, and the flush and shutdown that decide whether the last spans of a stopped pod arrive. The second module covers the metric and log pipelines: views, aggregation, periodic export, temporality, log processors and the delivery limits that apply to all three signals. Each module has a playground in which a Python service and an OpenTelemetry Collector run in a kind cluster, and a lab that repairs a broken configuration. The capstone combines both modules in one service with several faults.

## Learning Outcomes

After this section you can:

- Name the stages of the trace, metric and log pipelines in order and say which component performs each stage.
- Choose a sampler for a stated goal, and predict whether a child span is kept from the decision of its parent.
- Compare the simple and the batching span processor, and set the queue size, batch size and schedule delay so that a stated outage is absorbed.
- Explain why a pod can lose queued telemetry, and set the shutdown path and the termination grace period so that the last batch is exported.
- Write views that remove attributes, set histogram boundaries or drop a stream, and state the effect on cardinality.
- Choose an export interval and a temporality, and state what a failed export costs under each.
- Describe how a log record gets its trace and span identifiers, and size the batching log processor.
- Read the log of a Collector to confirm which signals arrive, and say why delivery from the SDK is at most once.
