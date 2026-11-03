# Question

Solve this question on: `terminal`

The `shuttle` service in `starfleet` is built with the OpenTelemetry Python SDK and sends OTLP over HTTP to the `collector` Service. The Collector prints everything it receives in its own log. The metric and log pipelines have four problems: metrics reach the Collector only every two minutes, the metric stream `shuttle.requests` has one data point for every client, the stream `shuttle.fuel.used` is not needed, and the log record queue holds only two records.

The SDK is configured only with environment variables on the `shuttle` Deployment. Change the Deployment, do not delete it, and do not edit the `shuttle-app` script or the Collector. Each change restarts the pod, and a new pod needs a few minutes to install the SDK.

1. Metric reader. The periodic reader must export every `5000` milliseconds or faster, at most every `10000`. Use the standard variable for the export interval. The exporter must send delta temporality for counters and histograms (`OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE`).

2. Views. Set `SHUTTLE_VIEWS` so that the script registers three views: `keys` (the stream `shuttle.requests` keeps only the attribute `shuttle.route`), `drop-fuel` (the stream `shuttle.fuel.used` is dropped) and `buckets` (the histogram `shuttle.request.duration` uses the boundaries 0.05, 0.1, 0.25, 0.5 and 1.0). The Collector log must show the effect: `shuttle.requests` without `shuttle.client`, no `shuttle.fuel.used`, and the bucket boundary `0.25`.

3. Log processor. The batching log record processor must queue at least `2048` records (`OTEL_BLRP_MAX_QUEUE_SIZE`) and export at most `512` per batch (`OTEL_BLRP_MAX_EXPORT_BATCH_SIZE`). The Collector must receive log records that carry a trace ID.

`kubectl` already points at the cluster. Read the Collector log with `kubectl -n starfleet logs deployment/collector --since=30s`.
