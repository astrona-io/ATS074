---
draft: true
exam_objectives:
  - Signals (Tracing, Metric, Log)
---
# Summary

A log record is one structured entry about one event. Its fixed fields are the event time, the observed time, the severity as text and as a number, the body, the attributes and the trace context. The severity number, from 1 to 24 in six bands, is the field that has one meaning in every library. The body holds a stable message, and the changing values belong in attributes. The Resource and the instrumentation scope travel with every record and say which entity and which library produced it.

Inside the SDK, a `LoggerProvider` owns the Resource, the processors and the attribute limits. A `Logger` creates records and hands them to the processors in the order they were registered. A processor can change a writable record, and an exporter receives read-only batches. The batch processor protects the application from the network, and in exchange it can drop records when its queue is full or lose them when the process is killed. The OTLP exporter appends `v1/logs` to the base endpoint. The variable `OTEL_LOGS_EXPORTER` only matters for automatic configuration.

Existing Python code reaches the SDK through a bridge handler on the standard `logging` module. The handler maps levels to severity numbers, turns extra fields into attributes and uses the current context to fill the trace ID, the span ID and the trace flags. A record has these identifiers only if it is created while a span is current. Records created after the span, in a thread without the context, or without a tracer provider have none. With sampling, a record can carry identifiers of a trace that was never recorded.

Events are log records with an event name, so records of the same kind can be queried together. Volume is reduced best at the source, by level, by the `enabled` check and by filters. The SDK stores nothing, so retention belongs to the Collector, the container runtime and the backend, and a missing record never proves that an event did not happen. Sensitive values are removed by not logging them, by a processor that runs before the batch processor, and by Collector rules.

Key facts:

- Severity numbers: TRACE 1 to 4, DEBUG 5 to 8, INFO 9 to 12, WARN 13 to 16, ERROR 17 to 20, FATAL 21 to 24.
- Batch processor defaults: 1000 ms delay, queue of 2048 records, batches of 512 records.
- The standard `WARNING` level becomes `WARN`, and `CRITICAL` becomes `FATAL`.
- A log record, a span and a metric from one process share one Resource when the code builds all providers with the same Resource.

<!-- astrona:playground:destroy -->
