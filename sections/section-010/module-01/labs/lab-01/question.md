# Question

Solve this question on: `terminal`

The `shuttle` service in the `starfleet` namespace sends traces, metrics and logs to the OpenTelemetry Collector in the same namespace. Its resource is wrong. It has no service name, so the data arrives as an unknown service, and it carries a request identifier as a resource attribute. The resource is set with environment variables on the `shuttle` Deployment.

Correct the resource so that the Collector receives this identity:

1. `service.name` is `shuttle`.
2. `service.namespace` is `starfleet`.
3. `service.version` stays `1.0.0`.
4. `deployment.environment.name` is `training`.
5. The resource has no `request.id` attribute.

Change the environment of the Deployment only. Do not delete or replace the `shuttle` or `collector` Deployments, and do not edit the ConfigMaps. Then show in the Collector output that the new resource arrives.

`kubectl` already points at the cluster. The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts, so each rollout takes up to a few minutes before telemetry arrives.
