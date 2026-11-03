# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory and network access to download Python packages.
- `kubectl` and `jq`.
- You know what an environment variable is and how to change one on a Deployment with `kubectl set env`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the namespace `starfleet`, an OpenTelemetry Collector and a Python service called `shuttle`. The service installs the OpenTelemetry SDK with `pip` at start, so every new pod needs about a minute.
