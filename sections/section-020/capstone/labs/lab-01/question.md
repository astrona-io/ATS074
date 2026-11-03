# Question

Solve this question on: `terminal`

A team added OpenTelemetry to the `shuttle` service in the `starfleet` namespace, and a Collector in the same namespace should receive its traces, metrics and logs. Nothing arrives, and a first look found several unrelated faults. The pod installs its Python packages with `pip` when it starts, so a restart takes a minute or more. Change only the environment of the `shuttle` Deployment. Do not edit the ConfigMap `shuttle-app`, do not change the image and do not touch the Collector.

1. The service must register the OpenTelemetry SDK, so that its tracer is a real SDK tracer and not a no-op tracer.

2. Recent Collector output must show the service name `shuttle`. The environment attribute `deployment.environment.name` with the value `staging` is already configured and must stay.

3. The service exports with OTLP over HTTP using protobuf. Its endpoint must reach the Collector HTTP receiver, and metrics must arrive.

4. Spans must pass through the custom processor `crew-tag` first and then the batch processor, so that spans at the Collector carry `starfleet.crew.size` with the value `4`. Only half of the root traces must be kept, and the sampler must follow the decision of a parent span. The application reads the processor list from `SHUTTLE_SPAN_PROCESSORS`.

5. Outgoing requests must carry the W3C `traceparent` header. The application prints the header names it injects on every loop.

6. Record the evidence in a ConfigMap `composability-evidence` in `starfleet` with these keys:
   - `tracer-class`: the tracer class name from the `[shuttle] pipeline:` line.
   - `injected-headers`: the header name the application injects, as the log line shows it.
   - `telemetry-sdk-version`: the value of `telemetry.sdk.version` in the Collector log.
   - `environment`: the value of `deployment.environment.name` in the Collector log.

`kubectl` already points at the cluster. The Collector runs as the Deployment `collector`, and its `debug` exporter prints every item it receives to its log.
