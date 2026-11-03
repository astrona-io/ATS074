# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory and internet access (the `scout` pod runs `pip install`).
- `kubectl` and `jq`.
- You can set Deployment environment variables, edit a ConfigMap, edit a DaemonSet and restart it, and read pod logs.

The lab starts a single-node kind cluster (Kubernetes 1.35). The `scout` pod needs about two minutes after every restart, because it installs its packages first.
