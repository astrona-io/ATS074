# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You can read a Deployment and its environment variables, and you can change them with `kubectl set env`.
- You know the fields of an OpenTelemetry log record and how the Python `logging` bridge fills the trace ID.

The lab starts a single-node kind cluster (Kubernetes 1.35) with an OpenTelemetry Collector and a Python service called `shuttle` in the `starfleet` namespace. The `shuttle` installs the OpenTelemetry SDK with `pip` when it starts, so every new pod needs one or two minutes before it exports records. The cluster needs access to the internet for that step.
