# Question

Solve this question on: `terminal`

A review of the `shuttle` service in the `starfleet` namespace found four problems in the telemetry that it sends to the OpenTelemetry Collector in the same namespace. The service has no service name, so its data arrives as an unknown service. A request identifier is set as a resource attribute. Its metrics are cumulative, but the metrics backend needs delta temporality for counters and histograms. And no data point of `shuttle.request.duration` carries an exemplar, so nobody can jump from the histogram to a trace.

Fix all four problems using the standard OpenTelemetry environment variables on the `shuttle` Deployment:

1. The resource must have `service.name` `shuttle`, `service.namespace` `starfleet`, `service.version` `1.0.0` and `deployment.environment.name` `training`, and no `request.id`.
2. Counters and histograms must arrive with delta temporality.
3. Measurements made inside a sampled span must be allowed to become exemplars.

Then write down what you observed in a ConfigMap `data-model-record` in `starfleet` with these keys:

- `service-identity`: the four resource attributes as you read them in the Collector output, written as `key=value` pairs separated by spaces.
- `temporality`: the aggregation temporality of `shuttle.requests` as the Collector prints it.
- `duration-unit`: the unit of `shuttle.request.duration` as the Collector prints it.

Do not change the program, delete the Deployments or edit the existing ConfigMaps. The Collector output must show a resource without `request.id`, a delta sum, an exemplar, and a log record that carries a trace ID, all from the last 40 seconds when you grade.

`kubectl` already points at the cluster. The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts, so each rollout takes up to a few minutes before telemetry arrives.
