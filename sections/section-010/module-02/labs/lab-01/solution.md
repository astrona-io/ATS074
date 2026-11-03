# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you change the environment. The `shuttle` pod needs a few minutes after the start before it sends data.

## Step 1: Read the starting state

Print the environment of the `shuttle` container and the temporality of the metrics:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
kubectl -n starfleet logs deploy/collector --since=20s | grep -A8 "Name: shuttle" | grep -E "Name:|AggregationTemporality:" | sort -u
```

The environment has `OTEL_METRICS_EXEMPLAR_FILTER=always_off` and no temporality setting. All sums and the histogram show `AggregationTemporality: Cumulative`.

## Step 2: Ask for delta temporality

The exporter reads `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE`. Set it to `delta` and wait for the new pod, because the metric provider reads the variable at startup:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-02/labs/lab-01 --keep
```

The check `temporality-configured` passes now. The check `collector-delta` passes when the Collector log of the last 40 seconds shows `shuttle.requests` as `Delta`. It polls for up to two minutes. The up-down counter `shuttle.queue.depth` stays cumulative under the `delta` preference, which is correct.

## Step 3: Allow exemplars

The filter `always_off` stops every measurement from becoming an exemplar. The setting that ties an exemplar to a sampled span is `trace_based`:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_METRICS_EXEMPLAR_FILTER=trace_based
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-02/labs/lab-01 --keep
```

The checks `exemplar-filter` and `collector-exemplars` pass when the new pod exports histogram points that carry exemplars. The `shuttle` records the histogram inside a sampled span, so `trace_based` accepts the measurements.

## Step 4: Confirm in the Collector output

Read the temporality and the exemplars:

```sh
kubectl -n starfleet logs deploy/collector --since=20s | grep -A8 "Name: shuttle" | grep -E "Name:|AggregationTemporality:" | sort -u
kubectl -n starfleet logs deploy/collector --since=20s | grep -A90 "Name: shuttle.request.duration" | grep -A8 "Exemplar #" | head -20
```

`shuttle.requests` and `shuttle.request.duration` show `Delta`. Each exemplar shows a trace ID and a span ID. Run the final grade. All five checks pass:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-02/labs/lab-01
```
