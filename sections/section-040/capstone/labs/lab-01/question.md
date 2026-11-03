# Question

Solve this question on: `terminal`

The `shuttle` service in the `starfleet` namespace uses the OpenTelemetry Python SDK for traces, metrics and logs. It sends all three signals to the `collector` Deployment, which prints them with the `debug` exporter (`kubectl -n starfleet logs deploy/collector`). The on-call team wants to start from a failed dispatch and reach its span and its log lines, and to graph the dispatch counter by service. Today none of that works. Fix it by changing the environment of the `shuttle` Deployment only. Do not change the program in the ConfigMap `shuttle-app`, and do not delete, scale down or replace any Deployment.

1. Shared identity. The three signals have no service name. Set the service name to `shuttle` and the resource attribute `deployment.environment.name` to `training`. Logs, spans and metrics must all arrive with both values.

2. Traces. The Collector receives no span. Find the reason in the environment and fix it, so that spans named `dispatch` arrive.

3. Metrics. The counter `shuttle.dispatch.count` does not arrive. It must reach the Collector within 40 seconds, so the export interval must be 15 seconds or less.

4. Logs. The `shuttle` must log at INFO or above, with no DEBUG record, and no record may carry the attributes `request.authorization` or `customer.email`.

5. Correlation. Every ERROR log record must carry a trace ID, and that trace ID must belong to a span that the Collector also receives.

The new pod installs the SDK when it starts and needs one or two minutes before the Collector shows its telemetry. `kubectl` already points at the cluster. The names of the application settings are in the environment of the Deployment.
