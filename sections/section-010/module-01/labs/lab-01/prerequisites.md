# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know how to read a Deployment and its environment variables, and how to read pod and Deployment logs with `kubectl logs`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with an OpenTelemetry Collector and the `shuttle` service in `starfleet`. The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts, so the start takes a few minutes.
