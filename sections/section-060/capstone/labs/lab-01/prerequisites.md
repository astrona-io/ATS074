# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory and internet access (the pods run `pip install`).
- `kubectl` and `jq`.
- You can read a Deployment, set an environment variable with `kubectl set env` and read pod logs.

The lab starts a single-node kind cluster (Kubernetes 1.35) with a collector, a `probe` and a `shuttle` in the `starfleet` namespace. Start-up takes a few minutes.
