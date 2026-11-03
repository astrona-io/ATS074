---
draft: true
exam_objectives:
  - Data Model
---
# Identity Of Spans, Metric Streams And Log Records

Each signal has its own way to say "this is one specific item". A span has identifiers and a position in a tree. A metric has a stream identity made from several fields. A log record has no identifier of its own, and it points to a span by copying trace and span identifiers. This part shows the fields of each signal, how the three connect, and what each field means when you read telemetry.

The three signals share the resource and the scope. They do not share one record format. Mixing up the models leads to wrong queries, for example looking for a log record ID or a metric trace ID that does not exist.

## Span identity and structure

A span is one timed operation. The fields that identify it and place it in a trace are:

- `trace_id`, 16 bytes shown as 32 hexadecimal characters. All spans of one trace share it.
- `span_id`, 8 bytes shown as 16 hexadecimal characters. It identifies the span inside the trace.
- `parent_span_id`. It is empty for a root span and holds the `span_id` of the parent for any other span.
- `trace_flags`, which include the sampled flag, and `trace_state`, an optional list of vendor values.

A span also has a name, a kind, a start time, an end time, attributes, events, links and a status. The kind says the role of the operation: `SERVER` for handling an incoming request, `CLIENT` for an outgoing request, `PRODUCER` and `CONSUMER` for asynchronous messaging, and `INTERNAL` for work inside the process. A span of kind `CLIENT` normally has a `SERVER` span as its child in another service.

The status has three values: `Unset`, `Ok` and `Error`. The default is `Unset`, which means no error was reported. A description is allowed only with `Error`. An event is a named point in time inside the span, with its own timestamp and attributes. A link points to another span, possibly in another trace. A link does not make that span a parent. It records a relation, for example a batch job that processes many earlier requests.

## Reading a span in the Collector output

Print the spans of the last seconds:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet logs deploy/collector --since=20s | grep -A22 "^Span #" | head -70
```

Each block starts with `Span #`. Under it you see `Trace ID`, `Parent ID`, `ID`, `Name`, `Kind`, the start and end times, the status code and the attributes. Find a span with `Kind: Server` and a name such as `GET /orders`. Its `Parent ID` is empty, so it is the root. Find the span named `HTTP GET probe` with `Kind: Client`. Its `Trace ID` equals the root's, and its `Parent ID` equals the `ID` of the root. That match is the whole parent-child relation. Nothing else links the two spans.

The server span carries the attributes `http.request.method`, `http.route` and `http.response.status_code`, and an event named `order.validated`. About one request in five sets `Status code: Error` with the message `upstream failed`, which shows a span in the error state.

## Metric stream identity

A metric is not one item but a stream of data points. OpenTelemetry defines the identity of a metric stream through these fields together: the resource, the scope, the metric name, the unit, the data type and the attributes of the data point. Two measurements with the same name but different attributes are two time series. Two instruments with the same name but different units conflict, and an SDK or a backend may reject or rename one.

The metric descriptor also holds a description. Description is metadata and does not take part in the identity. A metric data point does not carry a trace ID. A link from a data point to a trace exists only through an exemplar, which is optional and sampled.

Print the metric names that arrive, with their units:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -A3 "Name: shuttle" | grep -E "Name:|Unit:" | sort -u
```

You see `shuttle.requests` with unit `{request}`, `shuttle.request.duration` with unit `s`, `shuttle.queue.depth` with unit `{request}` and `shuttle.fuel.level` with unit `1`. The braces in `{request}` mark a unit that only counts things. The unit `1` marks a ratio without dimension.

## Log record identity

A log record has no identifier. It has a timestamp, an observed timestamp, a severity number and text, a body, attributes, and optional `trace_id`, `span_id` and trace flags. The SDK copies the trace and span identifiers from the active span when the program writes the log inside a span. This is how a log line connects to the span of the same request. The `shuttle` writes its log record inside the server span, so each record carries that span's identifiers.

Print one log record:

```sh
kubectl -n starfleet logs deploy/collector --since=20s | grep -A14 "^LogRecord #" | head -30
```

The record shows the severity, the body, such as `request handled on /orders`, the trace ID and the span ID. Compare the trace ID with the spans printed before: it matches the trace of the same request. The same record has `ObservedTimestamp` and `Timestamp`. The first is when the SDK saw the record, and the second is when the event happened. They can differ when a log comes from a file that a collector reads later.

## Trace flags and sampling

The `trace_flags` field holds the sampled bit. A sampler is the SDK component that decides at the start of a span whether the trace is recorded and exported. When a trace is not sampled, the span may exist for context propagation but the SDK does not export it. A log record written inside such a span still carries the trace ID, and the trace it points to may be missing in the backend. A missing trace for a log record is therefore not always a bug. The sampler configuration, for example `OTEL_TRACES_SAMPLER`, decides it.

## Worked reasoning: a log record without a trace

Take a log record whose trace ID is empty. Three causes are likely. The program wrote the log outside any span. The program wrote it in a thread or an asynchronous task that did not carry the context of the span. Or the log came from a library that does not use the OpenTelemetry API and a collector read it from a file. The record then has a body and a time, and nothing links it to a trace. The fix is in the instrumentation, not in the backend: write the log while the span is active, or pass the context into the new thread.

Now take the opposite case, a trace ID that is present but the trace is missing. Check the sampled flag first, then check that the exporter of the spans works. In the Collector output you can check both at once: the log record shows the trace ID, and a search for the same ID in the span blocks shows whether the span arrived.

## Span names and attributes

A span name should describe a class of operations and not one instance. `GET /orders/{id}` is a good name. `GET /orders/4711` is a poor name, because every order creates a new name and a backend cannot group the spans. The `shuttle` uses the route template in the name and in `http.route` for this reason. The specific value, if it is needed at all, belongs in an attribute of that span.

A span event is not a log record. An event lives inside one span and is exported with the span. A log record is exported through the logs pipeline and has its own severity. Use an event for a point in the life of one operation, such as `order.validated`, and a log record for a message that should also be searchable without the trace.

## How the three connect

Spans and logs connect through `trace_id` and `span_id`. Metrics connect to spans only through exemplars, and all three connect through the resource, because they share `service.name` and the other resource attributes. A query that starts from an alert on a metric can therefore go to the same service, then to traces of that service in the same time range. A direct jump from a metric point to one trace is possible only when an exemplar is present.

You can now tell what each field identifies. A span is placed by trace ID, span ID and parent span ID. A metric stream is the combination of resource, scope, name, unit, type and attributes. A log record is placed by time and optionally linked to a span. The open question for the metric stream is how a data point says over which time interval it counts.

## Common pitfalls

> [!WARNING]
> A parent-child relation exists only when the child `parent_span_id` equals the parent `span_id` inside the same trace. A link is not a parent. Metric data points have no trace ID, so do not search for one. A log record without trace context has no link to a span: logging outside a span, or in another thread without context, produces records with empty identifiers. `Status code: Unset` is not a failure and not a success; it means no status was set.
