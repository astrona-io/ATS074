# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the difference between the OpenTelemetry API and SDK, what `OTEL_SDK_DISABLED` does, how span processors, samplers, propagators and OTLP exporters are configured with environment variables, and how to read the Collector `debug` exporter output.

The lab starts a single-node kind cluster (Kubernetes 1.35) with a Collector and a Python service in `starfleet`. The service installs its packages with `pip` when it starts, so every restart takes a minute or more.
