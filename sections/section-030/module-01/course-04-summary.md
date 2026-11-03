---
draft: true
exam_objectives:
- Configuration
---
# Summary

The OpenTelemetry API records nothing until the application builds and registers an SDK. Initialization creates the providers, and each provider owns a sampler, processors or readers and exporters. The application registers them once, before the instrumented work starts. Work that starts earlier goes to a no-op implementation and is lost.

The SDK reads standard `OTEL_*` environment variables by fixed rules. A boolean is true only for the text `true` in any letter case. A number that cannot be parsed, an unknown enumerated name and an empty value all give a warning at most, and the default applies. A list is split at commas. Arguments that code passes to a constructor win over the environment, and each SDK documents which variables it supports.

The resource identifies the producer of the telemetry. `OTEL_SERVICE_NAME` sets `service.name` and wins over the same key in `OTEL_RESOURCE_ATTRIBUTES`. Code attributes win over both. When no source sets a name, the SDK uses `unknown_service`. A wrong resource does not stop telemetry, so the identity must be checked where the data arrives.

Key facts:

- The SDK is installed and enabled by the application, not by the API.
- `OTEL_SDK_DISABLED=true` selects a no-op SDK, and `yes` or `1` does not.
- Time variables are whole milliseconds, and `5s` is ignored.
- Resource lists use commas and percent-encoding, never semicolons.

<!-- astrona:playground:destroy -->
