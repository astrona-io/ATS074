---
draft: true
exam_objectives:
  - SDK Pipelines
---
# Log Pipelines And Delivery Limits

Applications have written logs for decades, and the logging libraries they use already work. The OpenTelemetry log pipeline does not ask the application to change its calls. It connects to the existing logging library through a bridge and adds what a plain log line lacks: a resource that describes the service, structured attributes and the identifiers of the active trace. This part follows a log record from the logging call to the exporter, explains the batching settings and then looks at the limits that apply to all three signals together.

## From a logging call to a log record

The pipeline has the same shape as the trace pipeline. A logger provider holds the resource and a list of log record processors. A processor receives each record and passes it to an exporter. The bridge is the first stage. In Python, the SDK offers a `LoggingHandler` that is attached to the standard `logging` module. When the application calls `logging.info`, the handler builds an OpenTelemetry log record and hands it to the logger provider. The log API itself is meant for such bridges and is not meant to be called from application code.

The `shuttle` script attaches the handler to a named logger of the `logging` module, with the batching processor behind the logger provider. Its log line is plain text, and the OpenTelemetry side adds the structure.

A log record has a timestamp, a severity number and text, a body, attributes, the resource and, when the call happens inside a span, the trace identifier and the span identifier of that span. The handler reads the identifiers from the current context, so the record is linked to the request that produced it, and a backend can show the logs of one trace. The `shuttle` script writes its log record inside the span of the request, so both carry the same trace identifier.

```mermaid
flowchart LR
  A["Logging call in application"] -->|"standard log record"| B["LoggingHandler bridge"]
  B -->|"adds trace and span ID"| C["Logger provider"]
  C -->|"emit"| D["Batch log processor"]
  D -->|"batches"| E["OTLP exporter"]
```

The diagram shows that the link to the trace is added in the bridge, before any processor runs. A processor that runs later sees the identifiers and does not create them.

## Log record processors

Two processors exist, with the same roles as for spans. The simple processor exports each record when it arrives and blocks the logging call during the export. The batching processor stores records in a bounded queue and exports them in batches from a worker thread. The batching processor is the default choice for a service, and it is configured with the `OTEL_BLRP_*` variables: `OTEL_BLRP_SCHEDULE_DELAY` (5000 milliseconds), `OTEL_BLRP_EXPORT_TIMEOUT` (30000), `OTEL_BLRP_MAX_QUEUE_SIZE` (2048) and `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE` (512). The batch size must not be larger than the queue size, or the processor refuses to start.

A service that logs at high volume can fill a queue in seconds. The sizing rule is the same as for spans: the queue should hold the records of the longest outage that you accept, and the batch size should stay smaller than the queue.

A queue that is too small is a common mistake, and so is the opposite. A queue of one million records hides a long outage but holds a lot of memory, and the shutdown then needs a long time to drain it. A moderate queue with a short delay is usually safer.

## Backpressure and delivery limits

Backpressure describes what happens when data is produced faster than it can be sent. The SDK does not slow down the application. When the queue of a batching processor is full, the processor drops records, logs a warning and goes on. This design protects the latency of the service, and it means that telemetry delivery is at most once. The same rule holds for spans. For metrics there is no queue, but the cardinality limit and the loss of unsent data on a kill play the same role.

The exporter adds its own limits. The OTLP exporters retry some failures with a growing delay until the export timeout ends, and they do not keep data for later. A destination that is down for longer than the timeout costs the data of that period. The Collector, placed between the service and the backend, can absorb short outages with its own queue, but the first link, from the SDK to the Collector, has only the SDK queue.

Lifecycle rules also apply to logs. The logger provider registers an exit handler by default, and a shutdown flushes the queue. A process that stops without that path loses the records in the queue, which often include the last error before a crash.

## Defaults of the three signals side by side

The batching settings of spans and logs mirror each other, and the metric reader has its own pair of settings. The values below are the defaults of the Python SDK.

| Purpose | Traces | Logs | Metrics |
| --- | --- | --- | --- |
| Delay between exports (milliseconds) | `OTEL_BSP_SCHEDULE_DELAY` 5000 | `OTEL_BLRP_SCHEDULE_DELAY` 5000 | `OTEL_METRIC_EXPORT_INTERVAL` 60000 |
| Timeout of one export (milliseconds) | `OTEL_BSP_EXPORT_TIMEOUT` 30000 | `OTEL_BLRP_EXPORT_TIMEOUT` 30000 | `OTEL_METRIC_EXPORT_TIMEOUT` 30000 |
| Queue size | `OTEL_BSP_MAX_QUEUE_SIZE` 2048 | `OTEL_BLRP_MAX_QUEUE_SIZE` 2048 | none |
| Batch size | `OTEL_BSP_MAX_EXPORT_BATCH_SIZE` 512 | `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE` 512 | none |

All three signals read the endpoint from `OTEL_EXPORTER_OTLP_ENDPOINT` and describe the service with the same resource, which comes from `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES`. A wrong endpoint therefore breaks all three at once, and a wrong queue size breaks only one of them. When telemetry is missing, first check which signals are missing, because this narrows the cause.

## Observing the log pipeline

Make sure the playground is running. Find a log record in the Collector output and check the identifiers:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -E 'LogRecord|Trace ID|Span ID|Body' | head -n 12
```

The record carries a trace identifier and a span identifier, and the same identifiers appear on the span of the request in the same output. The exact layout of the lines depends on the Collector version, so match on the field names. Now make the log queue small and point the exporter at a port where nothing listens, so that records pile up:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4319 OTEL_BLRP_MAX_QUEUE_SIZE=4 OTEL_BLRP_MAX_EXPORT_BATCH_SIZE=2
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Wait a minute and read the log of the service. The application still handles its requests, and the log also contains warnings from the SDK that records were dropped or could not be exported:

```sh
kubectl -n starfleet logs deploy/shuttle --since=60s | grep -iE 'queue|drop|fail|error' | head -n 8
```

Nothing reaches the Collector in this state, but the application does not stop or slow down. Restore the working endpoint and remove the two queue variables:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318 OTEL_BLRP_MAX_QUEUE_SIZE- OTEL_BLRP_MAX_EXPORT_BATCH_SIZE-
```

You have now followed all three signals through the SDK. Traces, metrics and logs share the resource and the exporter protocol, but they differ in how they collect, how they buffer and how they fail. A reliable pipeline needs sensible limits for each, a destination that is reachable and a shutdown path that is allowed to finish.

## Common pitfalls

> [!WARNING]
> A queue of a few records fills at once during an outage, and the oldest records are the ones that are lost. A batch size larger than the queue size stops the processor. Logs written before the provider is set up are not exported, because the handler has no provider yet. Log text that contains secrets is exported as it is. Do not rely on telemetry for audit records that must never be lost, because the SDK drops data under pressure by design.
