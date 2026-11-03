---
draft: true
exam_objectives:
  - Composability and Extension
---
# Summary

OpenTelemetry splits instrumentation from implementation. The API is a small set of interfaces that libraries call. The SDK implements those interfaces with providers, processors, readers and exporters, and the application installs it once. The dependency runs in one direction only: the SDK depends on the API, and the API depends on nothing from the SDK. A reusable library therefore imports the API, asks for a tracer or meter with its own instrumentation scope name, and leaves the destination and the policy to the application.

When no SDK is registered, the API runs as a no-op implementation. Calls succeed, spans are non-recording and nothing leaves the process. A proxy tracer fetched early starts recording when the application registers a provider. The environment variable `OTEL_SDK_DISABLED=true` makes an installed SDK return no-op components too, which lets an operator turn telemetry off without changing code. The two cases look different in the running system: the first shows API classes, the second shows an SDK provider that hands out a no-op tracer.

Stability rules decide what an application can depend on. The API and the SDK packages are stable `1.x` packages released and pinned together, while semantic conventions and many contributed packages are beta and can change names. The telemetry SDK version describes the code in the application, and the Collector version describes the pipeline that receives the data.

- Libraries depend on the API only and never set the global provider.
- Applications register providers once, early, from one place.
- The global provider can be set only once, and the first caller wins.
- Install the API and SDK packages at the same version and upgrade them together.
- An empty backend can mean no SDK, a disabled SDK, a wrong endpoint or an unsampled trace.

<!-- astrona:playground:destroy -->
