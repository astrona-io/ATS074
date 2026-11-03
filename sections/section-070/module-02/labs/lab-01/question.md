# Question

Solve this question on: `terminal`

The `starfleet` namespace has two OpenTelemetry Collectors. The `gateway` Deployment receives OTLP and prints every span and metric, so you can read it with `kubectl -n starfleet logs deploy/gateway`. The `agent` DaemonSet is a Collector in the agent role: it receives OTLP, processes it and exports it to the gateway. Its configuration is the ConfigMap `agent-config`. The agent container has the environment variable `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=starfleet-lab`.

The `shuttle` Deployment is an application that uses the OpenTelemetry SDK. Today it sends its telemetry straight to the gateway and the agent is unused. Fix this.

1. Make `shuttle` send OTLP over HTTP to the `agent` Service on port 4318. Change only the environment of the Deployment.

2. Add three processors to `agent-config` and use them in both the traces and the metrics pipeline, in this order: `memory_limiter` (set `check_interval`, `limit_mib` and `spike_limit_mib`), `resourcedetection` (detectors `env` and `system`) and `batch`. Write the `processors` list of each pipeline on one line in square brackets.

3. Make the running agent use the new configuration. Then the spans that arrive at the gateway must carry `host.name` and `deployment.environment.name` with the value `starfleet-lab`. The application does not set these attributes.

Rules:

- Do not edit `gateway-config`, do not delete a Deployment or the DaemonSet and keep the `otlp` exporter of the agent that sends to `gateway:4317`.
- The check reads the last minute of the gateway log, so wait for the new telemetry before you submit.

`kubectl` already points at the cluster. The `shuttle` pod needs about one minute to install its packages after a restart.
