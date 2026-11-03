# Question

Solve this question on: `terminal`

The `shuttle` service in `starfleet` is built with the OpenTelemetry Python SDK. The `collector` Service receives OTLP and prints everything in its own log. Today the Collector log shows no telemetry from the `shuttle`, and the team does not trust the pipeline. Repair the trace, metric and log pipelines and prove the result.

The SDK is configured only with environment variables on the `shuttle` Deployment. Change the Deployment, do not delete it, and do not edit the `shuttle-app` script or the Collector. Each change restarts the pod, and a new pod needs a few minutes to install the SDK. Start with the log of the `shuttle` pod.

1. Delivery. The `shuttle` must send OTLP over HTTP to the `collector` Service in `starfleet`. The pod log of the last minute must show no export failures.

2. Traces. Sample about a quarter of the traces and let child spans follow their parent: sampler `parentbased_traceidratio` with a ratio between `0.1` and `0.5`. Use the batching span processor (`SHUTTLE_SPAN_PROCESSOR=batch`) with a queue of at least `2048` spans, batches of at most `512` and a schedule delay of at most `5000` milliseconds.

3. Metrics. Export at most every `10000` milliseconds, with delta temporality. Register the views `keys` and `drop-fuel` in `SHUTTLE_VIEWS`. The Collector log must show `shuttle.requests` without the attribute `shuttle.client` and no `shuttle.fuel.used`.

4. Logs. The log record queue must hold at least `2048` records and a batch at most `512`. The Collector must receive log records that carry a trace ID.

5. Shutdown. On `SIGTERM` the script must flush and shut down its providers (`SHUTTLE_ON_TERM=shutdown`), and Kubernetes must wait at least `30` seconds before `SIGKILL`.

6. Evidence. Create the ConfigMap `pipeline-evidence` in `starfleet` with these keys, copied from the running pod: `endpoint` (the OTLP endpoint), `sampler`, `sampler-arg`, `metric-export-interval-ms`, and `observed-at` (the time of your last check in UTC, in the form `2026-11-03T10:15:00Z`).

`kubectl` already points at the cluster. Read the Collector log with `kubectl -n starfleet logs deployment/collector --since=30s`.
