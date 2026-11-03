# Question

Solve this question on: `terminal`

The `shuttle` service in the `starfleet` namespace sends traces, metrics and logs to the OpenTelemetry Collector in the same namespace. The metrics backend that reads the Collector output needs delta temporality for counters and histograms, and the team wants to jump from the request duration histogram to a trace. At the moment the service exports cumulative metrics, and its exemplar filter is set to `always_off`.

Change the `shuttle` so that:

1. Counters and histograms are exported with delta temporality. The metric `shuttle.requests` must arrive with `AggregationTemporality: Delta`.
2. Data points of `shuttle.request.duration` carry exemplars. Choose the setting that links an exemplar to a sampled span. Do not change the program or its ConfigMap.

Use the standard OpenTelemetry environment variables on the Deployment. Do not delete or replace the `shuttle` or `collector` Deployments. Then show in the Collector output that the delta sum and an exemplar with a trace ID arrive.

`kubectl` already points at the cluster. The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts, so each rollout takes up to a few minutes before telemetry arrives.
