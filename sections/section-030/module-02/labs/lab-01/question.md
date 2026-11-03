# Question

Solve this question on: `terminal`

The `shuttle` service in `starfleet` runs and prints its log lines, but the `collector` receives no spans and no metrics from it. The service reads its OpenTelemetry settings only from environment variables on the Deployment `shuttle`. The service log is `kubectl -n starfleet logs deploy/shuttle` and the Collector log is `kubectl -n starfleet logs deploy/collector`.

Change the Deployment so that all of this is true:

1. The service exports to the HTTP port of the Collector, through the Service `collector`, with the protocol `http/protobuf`.
2. Spans are sampled with a parent-based sampler that keeps 50 percent of the new traces. Use the standard sampler variables.
3. Metrics are exported every 5 seconds, and the Collector shows the metric `shuttle.docks`.

Do not change the application script or the Collector. A pod needs about a minute to start because it installs the SDK, and the checks wait for fresh telemetry.

`kubectl` already points at the cluster as the cluster administrator.
