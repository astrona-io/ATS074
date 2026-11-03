# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory and internet access (the `shuttle` pod runs `pip install`).
- `kubectl` and `jq`.
- You can read a ConfigMap, edit it with `kubectl edit` or `kubectl apply`, restart a DaemonSet with `kubectl rollout restart` and read a pod log.

The lab starts a single-node kind cluster (Kubernetes 1.35). The `shuttle` pod installs its packages when it starts, so it needs about one minute before it sends telemetry.
