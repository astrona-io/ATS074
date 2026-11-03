# Question

Solve this question on: `terminal`

The `scout` Deployment in `starfleet` is a Flask app with no OpenTelemetry code, started with `opentelemetry-instrument`. It must send its telemetry through a Collector in the agent role, the DaemonSet `agent`, to the Collector in the gateway role, the Deployment `gateway`. The gateway prints everything: `kubectl -n starfleet logs deploy/gateway`. A first review found these problems.

1. `scout` sends OTLP straight to the gateway. Send it over HTTP to the `agent` Service on port 4318.

2. The agent instrumentation of `scout` is wrong. The Flask instrumentation is disabled, there is no service name and the health check path `/healthz` produces spans. Make server spans appear, set `OTEL_SERVICE_NAME` to `scout` and exclude every URL that contains `healthz`. Change only the environment of the Deployment.

3. The agent configuration (ConfigMap `agent-config`) has only a `batch` processor. Use `memory_limiter` (with `limit_mib`, `spike_limit_mib` and `check_interval`), `resourcedetection` (detectors `env` and `system`) and `batch`, in this order, in both pipelines. Write the `processors` lists on one line in square brackets.

4. The agent DaemonSet mounts the host directory `/var/log` from the node. The agent only receives OTLP, so it needs no host files. Remove the volume and its mount. Do not add `privileged` or `hostNetwork`.

5. Make the running agent use the new configuration and pod template. Then fresh `scout` server spans at the gateway must carry `host.name` and `deployment.environment.name: starfleet-lab` (set by the agent from its own environment), and the gateway log must show no `GET /healthz` span in the last 40 seconds.

Rules:

- Do not edit `gateway-config` or the ConfigMap `scout-app`, do not delete a Deployment or the DaemonSet and keep the image of `scout`.
- The checks read the Deployment and DaemonSet specs and the last minute of the gateway log, so wait for new telemetry before you submit.

`kubectl` already points at the cluster. A new `scout` pod needs about two minutes to install its packages.
