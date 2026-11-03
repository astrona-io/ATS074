# Question

Solve this question on: `terminal`

The platform team takes over the `shuttle` service in the namespace `starfleet`. It exports to the `collector` in the same namespace. The service reads its OpenTelemetry settings only from environment variables on the Deployment `shuttle`. It starts with several faults. Find and fix them. The service log is `kubectl -n starfleet logs deploy/shuttle` and the Collector log is `kubectl -n starfleet logs deploy/collector`.

Change the Deployment so that all of this is true:

1. The resource of the telemetry has `service.name` set to `shuttle`, `service.namespace` set to `starfleet`, `deployment.environment.name` set to `production` and `service.version` set to `3.0.0`.
2. Fresh spans (`dock`) and fresh metrics (`shuttle.docks`) reach the Collector over OTLP/HTTP. The OTLP endpoint is the HTTP port of the Service `collector`.
3. Traces use the parent-based ratio sampler with a ratio of 0.25. The batch span processor exports every second or faster, and metrics export every 5 seconds or faster.
4. The OTLP headers value is `x-starfleet-token=hailing-frequency-7`. It must not be written as plain text in the Deployment. Store it in a Secret `collector-auth` in `starfleet` under the key `otlp-headers` and read it into the variable `OTEL_EXPORTER_OTLP_HEADERS` from that Secret.

Do not change the application script or the Collector. A pod needs about a minute to start because it installs the SDK, and the checks wait for fresh telemetry.

`kubectl` already points at the cluster as the cluster administrator.
