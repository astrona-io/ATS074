---
draft: true
exam_objectives:
- Configuration
---
# Summary

The OTLP exporter must match the receiver. gRPC and HTTP are different transports with different default ports, 4317 and 4318, and a client of the wrong kind fails on an open port. `OTEL_EXPORTER_OTLP_ENDPOINT` is a base URL, and the SDK adds `v1/traces`, `v1/metrics` or `v1/logs` for the HTTP transports. A signal-specific endpoint is used exactly as written. Headers are comma-separated `key=value` pairs and belong in a Secret when they hold a token. The timeout is in milliseconds.

The sampler decides at span start whether a span is recorded. The built-in samplers are `always_on`, `always_off`, `traceidratio` and their parent-based forms, and the default is `parentbased_always_on`. A ratio sampler needs an argument from 0 to 1. A parent-based sampler follows the parent so that a trace stays whole across services. Metrics are not sampled. An unknown sampler name is ignored with a warning, and the default applies.

Batching trades overhead for delay. The batch span processor exports on a schedule from a bounded queue, and a full queue drops spans. The metric reader exports on a timer, with a default of sixty seconds. A process that stops between exports loses data unless it flushes.

A declarative configuration file describes the whole pipeline as structured YAML. When `OTEL_CONFIG_FILE` is set, the SDK ignores the other SDK environment variables except those the file references. When telemetry is missing, check the layers in order: the SDK switch, the sampler, the queue, the exporter and the Collector. Confirm every fix with fresh telemetry at the Collector.

Key facts:

- Port 4317 is gRPC and port 4318 is HTTP for the Collector OTLP receiver.
- Only `OTEL_EXPORTER_OTLP_ENDPOINT` gets a signal path appended.
- `parentbased_traceidratio` with `0.5` samples about half of the new traces.
- Defaults: batch delay 5000 ms, queue 2048 spans, metric interval 60000 ms, export timeout 10 seconds.

<!-- astrona:playground:destroy -->
