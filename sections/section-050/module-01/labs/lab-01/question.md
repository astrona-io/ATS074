# Question

Solve this question on: `terminal`

The `shuttle` service in `starfleet` is built with the OpenTelemetry Python SDK and sends OTLP over HTTP to the `collector` Service. The Collector prints everything it receives in its own log. Today the Collector shows no spans from the `shuttle`. The team wants the trace pipeline to keep about half of the traces, send them in batches and not lose queued spans when Kubernetes stops the pod.

The SDK is configured only with environment variables on the `shuttle` Deployment. Change the Deployment, do not delete it, and do not edit the `shuttle-app` script or the Collector. Each change restarts the pod, and a new pod needs a few minutes to install the SDK.

1. Sampling. Keep about half of all traces. A span that has a parent must follow the sampling decision of its parent. Use the sampler that fits and set its ratio to `0.5`.

2. Processing. Use the batching span processor (`SHUTTLE_SPAN_PROCESSOR=batch`). The queue must hold at least `4096` spans, a batch must have at most `256` spans, and the schedule delay must be at most `2000` milliseconds. Use the standard `OTEL_BSP_*` variables.

3. Shutdown. When the pod receives `SIGTERM`, the script must flush and shut down its providers (`SHUTTLE_ON_TERM=shutdown`). Kubernetes must give the pod at least `30` seconds before it sends `SIGKILL`.

4. Delivery. After the change, the Collector log must show `shuttle.dock`, `shuttle.launch` or `shuttle.scan` spans from the new pod.

`kubectl` already points at the cluster. Read the Collector log with `kubectl -n starfleet logs deployment/collector`.
