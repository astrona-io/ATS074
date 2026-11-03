# Question

Solve this question on: `terminal`

The `shuttle` application in the `starfleet` namespace creates spans with the OpenTelemetry Python SDK and sends them over OTLP/HTTP to the `collector` Deployment. The Collector prints every span to its log. The on-call engineer reports three problems: no trace from the `shuttle` reaches the Collector, the spans (when they arrive) have no service name, and a failed operation is not marked as a failure. Fix all three without deleting or replacing a Deployment or its image.

1. Identity. The spans must carry the resource attribute `service.name` with the value `shuttle`. They must also carry `deployment.environment.name` with the value `lab`, and keep the existing `service.version` value `1.0.0`. Use the standard OpenTelemetry environment variables on the `shuttle` Deployment.

2. Sampling. The sampler must keep every trace. After the fix, spans named `dock`, `scan` and `report` must reach the Collector, and the `scan` span must show its parent span in the Collector log.

3. Failure evidence. Every third trace fails inside the `report` span. The failed `report` span must have status code `Error` and an `exception` event in the Collector log. The cause is in the application code in the `shuttle-app` ConfigMap. The `shuttle` pod reads that file only when it starts.

`kubectl` already points at the cluster. The `shuttle` pod installs its packages with `pip` when it starts, so a new pod needs a few minutes before spans appear.
