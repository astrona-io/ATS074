# Question

Solve this question on: `terminal`

The `shuttle` service in the namespace `starfleet` exports telemetry to the `collector`, but the platform team sees the wrong identity or no telemetry at all. The service reads its OpenTelemetry settings only from environment variables on the Deployment `shuttle`. Look at the environment with `kubectl -n starfleet get deploy shuttle -o yaml` and read the Collector log with `kubectl -n starfleet logs deploy/collector`.

Change the Deployment so that all of this is true:

1. The SDK is enabled and the service exports spans and metrics again.
2. The telemetry that reaches the Collector has the resource attribute `service.name` with the value `shuttle`. No telemetry with another service name may remain in the configuration.
3. The resource also has `service.namespace` set to `starfleet`, `deployment.environment.name` set to `production` and `service.version` set to `2.4.1`.

Do not change the application script or the Collector. A pod needs about a minute to start because it installs the SDK, and the checks wait for fresh telemetry.

`kubectl` already points at the cluster as the cluster administrator.
