# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory and internet access (the pods run `pip install`).
- `kubectl` and `jq`.
- You can read a Deployment, set environment variables with `kubectl set env` and read pod and Collector logs.

The lab starts a single-node kind cluster (Kubernetes 1.35). The `scout` pod installs its packages when it starts, so it needs about two minutes before it is ready.
