# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know how to read a Deployment, set environment variables with `kubectl set env`, and read pod logs.
- You know the span processors, the OTLP endpoint and protocol variables, and what a sampler and a propagator do.

The lab starts a single-node kind cluster (Kubernetes 1.35) with a Collector and a Python service in `starfleet`. The service installs its packages with `pip` when it starts, so every restart takes a minute or more.
