---
draft: true
exam_objectives:
  - Data Model
---
# Attributes, Units And Timestamps

Every span, data point and log record carries attributes, a unit where it measures something, and times. Small mistakes here are hard to find later: a high-cardinality attribute can make a metric backend slow or expensive, a wrong unit makes a graph look a thousand times too large, and a wrong timestamp puts an event in the wrong place on a timeline. This part defines the three things exactly and shows them in the output of the `shuttle` service.

An attribute is a key-value pair that adds detail to a resource, a scope, a span, an event, a link, a data point or a log record. The key is a non-empty string. The value has a type, and the model limits the types so that every backend can store them.

## Attribute types and rules

The value of an attribute is one of these types: string, boolean, 64-bit signed integer, double-precision floating point number, byte array, or an array of one of the first four types. Newer versions of the specification also allow maps and arrays of mixed values in some places, but the safe common set is the list above. There is no null in the basic model. A key appears once per item: if code sets the same key twice, the last value replaces the first.

The SDK can enforce limits. `OTEL_ATTRIBUTE_COUNT_LIMIT` limits how many attributes an item can have, with a default of 128. `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` limits the length of string values, with no limit by default. Spans have their own limits too, such as `OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT` and `OTEL_SPAN_EVENT_COUNT_LIMIT`. When a limit is exceeded, the SDK drops or truncates the data and does not raise an error in the program. Some SDKs count the dropped attributes and export the count, so a consumer can see that data was lost.

Attribute keys use lowercase words separated by dots, for example `http.request.method`. The dot builds a namespace. Do not reuse a namespace that the semantic conventions own for something else, and put your own attributes under your own prefix, such as `starfleet.order.id`.

### Where attributes exist

Attributes exist on seven kinds of object. Knowing which one an attribute sits on tells you how long it lives and how widely it applies:

- Resource attributes describe the producer and apply to every item it exports.
- Scope attributes describe the instrumentation scope.
- Span attributes describe one operation, and span event and span link attributes describe one event or one link.
- Data point attributes split a metric into series.
- Log record attributes describe one log entry.

The same key can appear on several levels with different meaning, so always check the level before you filter on it.

## Cardinality

Cardinality is the number of different values an attribute can take. For a span attribute, high cardinality is acceptable, because each span is stored on its own. For a metric attribute, each different combination of attribute values creates a separate time series. Look at the `shuttle`: its three metrics use `http.request.method`, `http.route` and `http.response.status_code`. The program uses three routes and two status codes, so each metric has at most six series. If the program used the full URL with an order number as an attribute, the series count would grow with every order, and the memory of the SDK and the storage of the backend would grow with it.

The rule is simple. Put values with a small, known set of options on metrics: method, route template, status code, environment. Put identifiers that grow without bound, such as order numbers or user names, on spans and logs only. The SDK also has a cardinality limit for metrics. When the limit is reached, the SDK folds the extra series into one series with the attribute `otel.metric.overflow=true`, so it keeps memory bounded but loses detail.

### A worked cardinality calculation

Count the series of one metric by multiplying the number of values of each attribute. The `shuttle` records `shuttle.requests` with three attributes:

- `http.request.method` has one value, `GET`.
- `http.route` has three values: `/orders`, `/orders/{id}` and `/status`.
- `http.response.status_code` has two values: `200` and `500`.

The series count is 1 x 3 x 2 = 6. Now suppose a developer adds `starfleet.order.id` to the metric, and the service handles 10,000 different orders a day. The count becomes 1 x 3 x 2 x 10,000 = 60,000 series. Each series needs memory in the SDK until the next export, and the backend must index and store each one. Nothing breaks at the first request, which is why this mistake survives review. The cost appears under load.

The same order identifier on a span costs one more attribute on one span. It stays useful there, because a trace search by order identifier finds the exact request.

## Units

A unit tells which measurement the number has. The metric descriptor carries the unit as a string, and OpenTelemetry uses the Unified Code for Units of Measure, UCUM, as its basis. Common units are `s` for seconds, `ms` for milliseconds, `By` for bytes, and `1` for a dimensionless ratio. Curly braces mark an annotation that names the counted thing and has no unit, such as `{request}` or `{error}`.

A unit is part of the metric identity. The semantic conventions prefer base units without prefixes, for example seconds and bytes, so values from different services compare directly. A histogram of request duration in `ms` and another in `s` with the same name cannot be combined without conversion. The SDK does not convert, so the producer must send the right number for the declared unit. A program that declares `s` and records milliseconds sends data that is a thousand times too large and says nothing about it.

Print the metric descriptors of the `shuttle`:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -A5 "Name: shuttle" | grep -E "Name:|Description:|Unit:" | sort -u
```

Each metric shows `Name`, `Description` and `Unit`. The duration histogram `shuttle.request.duration` has the unit `s`, and the program records seconds, so the data is consistent. Names for the counter and the gauge use `{request}` and `1`. The description is for people and is not part of the identity.

### A worked unit mistake

A developer measures the duration of a request with `time.time()` and records the difference. That value is in seconds. The instrument was created with `unit="ms"` by copying code from another service. A dashboard that trusts the unit labels the value `0.045` as 0.045 milliseconds, when the request took 45 milliseconds. A second service records real milliseconds, `45.0`, with the same name and the same unit. A query that averages both now mixes numbers that differ by a factor of 1,000.

Two rules prevent this. First, choose the base unit from the semantic conventions, which is `s` for durations. Second, check the unit and a typical value together when you read the descriptor. A request duration of `0.045` with the unit `s` is plausible. A value of `45` with the unit `s` is not.

## Timestamps

OpenTelemetry stores time as nanoseconds since the Unix epoch, 1 January 1970 UTC, in an unsigned 64-bit integer. The Collector prints it as a UTC time with nanosecond precision. A span has a start time and an end time. A log record has `Timestamp`, when the event happened, and `ObservedTimestamp`, when the system saw it. A metric data point has a `Timestamp`, the end of the interval it describes, and for most types a `StartTimestamp`, the start of that interval. The next part uses the start time to explain temporality.

The producer sets the times with its own clock. The Collector does not replace them. When the clock of a host is wrong, every time from that host is wrong in the same way, and the data from two hosts that disagree shows events in the wrong order. Time zones do not exist at this level: all times are UTC.

Read the times of some data points:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -E "StartTimestamp|^Timestamp" | head -8
```

Each data point prints its `StartTimestamp` and its `Timestamp`. For a cumulative sum, the start time stays fixed at the start of the process, and the timestamp grows with each export. The distance between two consecutive timestamps of one series is close to the export interval, which the playground sets to 5 seconds with `OTEL_METRIC_EXPORT_INTERVAL=5000`. The variable value is in milliseconds.

### A worked timeline

Take a log record with `Timestamp` 12:00:00.100 and `ObservedTimestamp` 12:00:07.400. The event happened at 12:00:00.100, and the pipeline saw it 7.3 seconds later, for example because a collector read it from a file after a restart. A span that ended at 12:00:00.350 and a log record at 12:00:00.100 belong together in a timeline sorted by `Timestamp`. A timeline sorted by `ObservedTimestamp` would place the log after the span and suggest the wrong order. When an `ObservedTimestamp` is the only time available, the record gives the time of observation and not the time of the event.

You now know how attributes, units and times are stored, and where each one can go wrong. The open question is how a data point turns many measurements into one number over an interval, which depends on the kind of data point and on its temporality.

## Common pitfalls

> [!WARNING]
> An attribute that grows without bound on a metric creates a new time series for each value. Put identifiers on spans and logs instead. The SDK does not check that a recorded number matches the declared unit. Exceeding an attribute limit drops data silently. Times are UTC nanoseconds from the producer's own clock, and the Collector does not correct them.
