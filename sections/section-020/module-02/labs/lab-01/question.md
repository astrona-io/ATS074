# Question

Solve this question on: `terminal`

The `shuttle` service in the `starfleet` namespace was configured by a colleague who left a half-finished SDK pipeline. The Collector in the same namespace receives nothing from it. The pod installs its Python packages with `pip` when it starts, so a restart takes a minute or more. Change only the environment of the `shuttle` Deployment. Do not edit the ConfigMap `shuttle-app` and do not change the image.

1. Repair the export path. The service exports with OTLP over HTTP using protobuf. Its endpoint must reach the Collector HTTP receiver, and metrics must arrive at the Collector.

2. Fix the span processors. The service must use the custom processor `crew-tag` first and then the batch processor, and the batch processor must export every 2 seconds. The application reads the list from `SHUTTLE_SPAN_PROCESSORS`.

3. Fix the sampler. Spans must be recorded for every root trace, and the sampler must follow the sampling decision of a parent span.

4. Confirm that spans reach the Collector with the attribute `starfleet.crew.size` set to `4`.

5. Record the evidence in a ConfigMap `pipeline-evidence` in `starfleet` with these keys:
   - `processors`: the list of span processors, as the `[shuttle] pipeline:` line in the pod log prints it.
   - `exporter-port`: the port of the OTLP endpoint of the service.
   - `crew-size`: the value of `starfleet.crew.size` that the Collector log shows.

`kubectl` already points at the cluster. The Collector runs as the Deployment `collector`, and its `debug` exporter prints every item it receives to its log.
