# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory and network access (the `shuttle` pod installs the OpenTelemetry SDK with `pip`).
- `kubectl` and `jq`.
- You know what a span, a trace, a resource, a sampler and a span processor are, and you can set environment variables on a Deployment with `kubectl set env`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with an OpenTelemetry Collector and a Python application in the `starfleet` namespace. The first start takes several minutes because the application installs its packages.
