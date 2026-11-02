---
draft: true
exam_objectives:
- Composability and Extension
---
# API Independence, SDK Components And Extension Contracts

OpenTelemetry separates instrumentation APIs from recording implementations so applications can compose a telemetry system. A reusable library can create spans or measurements through an API without choosing a storage backend. The application configures the SDK, sampling, processing and export. This separation avoids requiring every dependency to ship its own incompatible destination and operational policy.

Providers create or supply signal-specific implementations. A tracer provider supplies tracers associated with instrumentation scope. A meter provider supplies meters and instruments. A logger provider supplies logging bridges or recording behavior according to the language's support. These names describe related roles, but the lifecycle and configuration details remain signal- and language-specific.

The SDK pipeline contains components with distinct responsibilities. Span processors observe span lifecycle and can pass ended spans toward export. Metric readers collect and export aggregated measurements through their corresponding interfaces. Log processors handle emitted records. Exporters deliver compatible data to a destination. A component's presence in the same package ecosystem does not make it valid for every signal.

For example, an application can use a batch span processor with an OTLP trace exporter. The processor manages batching and invokes export according to its lifecycle. The exporter implements transport and destination handling. A metric reader has a different contract and cannot simply replace the span processor because both mention intervals. Composition works through supported interfaces, not similar-sounding names.

Configuration controls resource identity, sampling and other policies. Libraries should not continually replace the application's global provider after initialization. Doing so can split telemetry across different implementations and cause inconsistent behavior. The owning application needs a clear initialization point and lifecycle so instrumented dependencies share an intended policy.

Extensions can add custom samplers, processors, exporters or resource detection where the selected SDK supports them. These components need deliberate performance and failure behavior. A processor that blocks application work on an unreliable destination can turn an observability dependency into a user-facing availability problem. A custom exporter that silently discards rejected records can hide the very failure the team needs to diagnose.

Lifecycle methods matter because buffered data can remain in memory. Force-flush and shutdown behavior have defined purposes and timing limits. Calling shutdown prematurely can stop recording while the application continues to serve requests. Never calling it during controlled termination can leave queued records undelivered. The design should fit the process lifetime rather than assume all applications are long-lived servers.

Interoperability includes protocol and semantic compatibility. An OTLP exporter needs a destination supporting the selected protocol and signal. A metrics destination may expect a particular temporality or aggregation representation. Resource and scope information should remain meaningful across transformations. A successful TCP connection is narrower evidence than successful signal ingestion.

Consider a plugin that adds a custom diagnostic processor to a shared SDK. It should document what it observes, what data it retains and whether it can alter or reject observations. Its error path should avoid recursive telemetry loops in which reporting an exporter failure invokes the same failing exporter again. Extension flexibility makes these designs possible but does not remove their operational responsibility.

The useful mental model is a set of contracts owned at different layers: instrumentation creates observations, the SDK implements recording policy, pipeline components shape the data and exporters move it. Students can locate a failure by asking which contract stopped being satisfied rather than replacing the entire telemetry stack whenever a record is absent.

## Common pitfalls

> [!WARNING]
> Do not let reusable libraries take over application-wide provider or exporter policy. Match components to the supported signal interfaces and lifecycle. Custom extensions need bounded work and observable failures; type compatibility alone does not prove operational compatibility.
