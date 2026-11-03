# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`.
- You know how to edit environment variables on a Deployment and how to read pod logs with `kubectl logs`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the `starfleet` namespace. The `shuttle` pod installs the OpenTelemetry SDK with pip when it starts, so every restart needs about two minutes before new metrics appear in the Collector log.
