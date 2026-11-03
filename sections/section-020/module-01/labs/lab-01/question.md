# Question

Solve this question on: `terminal`

The `shuttle` service in the `starfleet` namespace creates spans, metrics and log records through the OpenTelemetry API, and a Collector in the same namespace should receive them. The Collector shows nothing from the service, and the service itself runs without errors. The pod installs its Python packages with `pip` when it starts, so a restart takes a minute or more.

1. Find why no telemetry leaves the service and fix it by changing the environment of the `shuttle` Deployment only. Do not edit the ConfigMap `shuttle-app` and do not change the image.

2. Give the data a service name. Recent Collector output must show the resource attribute `service.name` with the value `shuttle`.

3. Confirm that spans, metrics and log records from the instrumentation scope `starfleet.navigation` reach the Collector.

4. Record the evidence in a ConfigMap `api-sdk-evidence` in `starfleet` with these keys:
   - `tracer-class`: the class name of the tracer, as the `[shuttle] pipeline:` line in the pod log prints it after the fix.
   - `scope-name`: the instrumentation scope name that the Collector prints for the spans.
   - `telemetry-sdk-version`: the value of the resource attribute `telemetry.sdk.version` in the Collector log.
   - `service-name`: the service name in the resource.

`kubectl` already points at the cluster. The Collector runs as the Deployment `collector`, and its `debug` exporter prints every item it receives to its log.
