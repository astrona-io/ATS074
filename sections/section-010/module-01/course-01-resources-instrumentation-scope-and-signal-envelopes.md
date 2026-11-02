---
draft: true
exam_objectives:
- Data Model
---
# Resources, Instrumentation Scope And Signal Envelopes

OpenTelemetry defines signal-specific data models with shared identity concepts. Resources identify the entities producing telemetry. Instrumentation scopes identify the instrumentation libraries or sources within those entities. Observations then carry attributes and fields appropriate to their signal. This structure lets consumers distinguish the service that performed work from the library that recorded it.

A resource can describe a service instance and its environment. Instrumentation scope can describe a particular instrumentation package and version. Operation attributes belong on the relevant span, metric point or log record. Confusing these levels can create misleading grouping. An individual request identifier should not become a resource attribute that changes the service identity for every request.

Spans describe timed operations with trace and span identifiers, parent relationships where applicable, start and end timestamps, attributes, events and status. A span kind helps express whether the operation is a server, client or another role. Links can associate operations beyond a simple parent-child tree, such as work influenced by multiple messages. A link does not make the linked span the parent automatically.

Metric data has additional temporal and aggregation meaning. An instrument produces measurements, while the SDK's aggregation and readers turn them into exported points. Sums, gauges and histograms describe different kinds of evidence. Delta and cumulative temporality describe whether an aggregation covers a recent interval or an accumulating interval. Units and monotonicity help consumers interpret changes correctly.

For example, a cumulative request sum can increase until its producing process restarts or the accumulation otherwise resets. A delta point describes an interval contribution rather than that entire history. Adding them together as if they were interchangeable values can produce misleading rates. An exporter or backend may transform representations, so compatibility should be checked across the whole path.

Log records can carry a body, severity, attributes and timestamps. They can include trace and span identifiers when emitted with relevant context. Event occurrence time and observed time can differ when collection is delayed. A record arriving later does not necessarily describe a later event. This matters when investigators assemble an incident timeline across buffered or retried pipelines.

Attributes are typed values with names and scopes. They should express useful information without unnecessary sensitive data or unbounded dimensions. A large raw response body is not automatically a good attribute merely because the model can carry text. The signal's intended analysis, volume and retention influence what should be recorded.

The shared transport can carry these signals without making them identical. OTLP describes protocols and representations for telemetry delivery. A destination may support only selected signals or map fields into its own storage model. A successful connection therefore does not establish that all metadata survives with the intended meaning. Interoperability includes signal and model compatibility as well as address reachability.

Consider a trace and log describing one checkout failure. Their resource identity should agree on the producing service, and the log's correlation fields should refer to the relevant trace context. The metric counter for failed checkouts can describe the population but need not identify every individual trace. Keeping the identities and models separate lets the three observations complement one another without overstating their relationship.

## Common pitfalls

> [!WARNING]
> Resource identity, instrumentation scope and observation attributes serve different purposes. Do not combine delta and cumulative metric values without understanding their temporal meaning. A common transport does not guarantee complete field preservation or identical backend interpretation.
