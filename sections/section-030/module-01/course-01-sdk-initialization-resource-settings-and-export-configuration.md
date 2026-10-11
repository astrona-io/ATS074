---
draft: true
exam_objectives:
- Configuration
---
# SDK Initialization, Resource Settings And Export Configuration

SDK configuration connects instrumentation to actual recording and delivery behavior. The application chooses providers, resource identity, sampling and signal pipelines, then initializes them before the relevant work begins. Exporter settings connect those pipelines to compatible destinations. This is separate from Collector configuration: the SDK runs with the application, while a Collector can process telemetry after it leaves the application.

Initialization timing is important. Automatic hooks may need to attach before framework or client libraries are loaded. Manual API calls need the intended provider available when work starts. Configuring the exporter after startup does not generally recreate observations that were never recorded. A missing early trace can therefore be an initialization problem even when later traces export correctly.

Resource settings identify the producing application. A stable service name and suitable environment identity help consumers group telemetry accurately. Host and process detection can add context where supported. Explicit attributes and detected attributes can interact according to the selected SDK's merge and precedence behavior. The final resource should describe the producer truthfully rather than inherit an unrelated default identity.

Standard environment variables can configure service identity, export protocol, endpoints and other options where supported. Language implementations and distributions do not necessarily implement every specification feature at the same time. Programmatic configuration may also take precedence or provide additional controls. An author should verify the selected SDK's support instead of assuming that setting a familiar variable always changes runtime behavior.

Endpoint configuration includes more than a hostname. OTLP can use gRPC or HTTP-based transport, with signal-specific path and configuration behavior. A destination that supports one protocol does not automatically support the other on the same listener. TLS trust, authentication headers and network access are additional boundaries. A successful address lookup is not proof that the destination accepts the selected signal.

Consider an application sending traces to a local Collector. The service emits spans, the processor queues them and the exporter attempts delivery. If the exporter selects the wrong protocol, the failure occurs after recording. Increasing the sampling rate will create more queued data without repairing transport. If sampling intentionally excludes the request, the exporter has no span to deliver. The two cases need different evidence.

Sampling policy determines which trace observations are retained or recorded under the selected model. Parent-based behavior can preserve a consistent decision across a request where supported. A sampling decision should be understood alongside manual span creation and remote context. Setting an exporter endpoint does not override a sampler that excludes observations.

Batch sizes, timeouts and flush behavior affect the tradeoff between overhead and delivery delay. Short-lived processes need a lifecycle that allows queued data to be flushed within their termination budget. Long-lived services need bounded queues and observable failure behavior. A very large queue can postpone visible loss while consuming memory and increasing delay; it is not a substitute for a healthy destination.

Secrets in exporter configuration need controlled delivery and limited authority. Authentication headers should not be copied into logs or public examples. Browser applications have different trust constraints because users can inspect delivered code and configuration. A credential safe in a protected server process may be inappropriate in a browser exporter.

Useful diagnosis separates identity, recording, buffering and transport. Confirm the intended resource, supported configuration path, provider initialization and sampling behavior before attributing every missing record to the Collector. Then examine exporter failures and destination acceptance. This sequence follows the actual contracts without inventing successful output or requiring a live exercise.

## Common pitfalls

> [!WARNING]
> Familiar environment-variable names do not prove language support or precedence. Match endpoint and protocol, initialize before relevant work and protect authentication settings. More sampling or a larger queue cannot repair an incompatible destination.
