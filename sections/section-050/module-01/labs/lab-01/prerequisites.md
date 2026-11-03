# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory, and internet access for the `pip install` that the `shuttle` pod runs at start.
- `kubectl` and `jq`.
- You know the difference between a sampler, a span processor and an exporter, and the `OTEL_BSP_*` variables of the batching span processor.

The lab starts a single-node kind cluster (Kubernetes 1.35) with an OpenTelemetry Collector and the `shuttle` service in `starfleet`. The first pod start takes several minutes.
