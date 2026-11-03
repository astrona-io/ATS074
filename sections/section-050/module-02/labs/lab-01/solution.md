# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-02/labs/lab-01
```

The first start takes several minutes because the `shuttle` pod installs the SDK with `pip`.

## Step 1: Read the starting configuration

Print what the SDK was told at start, and the environment of the Deployment:

```sh
kubectl -n starfleet logs deployment/shuttle | grep '\[shuttle\] config'
kubectl -n starfleet get deployment shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + (.value // "(pod field)")'
```

The line shows `metric_interval=120000`, `views=none`, `temporality=cumulative` and `blrp_queue=2`. The periodic metric reader collects and exports once every 120 seconds, so the Collector sees metrics only twice in four minutes.

## Step 2: Export metrics faster with delta temporality

Set the interval in milliseconds and the temporality preference in one command, so the pod restarts once:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_METRIC_EXPORT_INTERVAL=5000 OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-02/labs/lab-01 --keep
```

The check `metric-reader` passes. Counters now report `AggregationTemporality: Delta` in the Collector log.

## Step 3: Register the views

A view changes the stream an instrument produces. The script builds one view for each name in `SHUTTLE_VIEWS`:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_VIEWS=keys,buckets,drop-fuel
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
```

Check the effect in the Collector log. The first command finds the stream, the second finds the bucket boundary, and the last two print nothing:

```sh
kubectl -n starfleet logs deployment/collector --since=30s | grep 'Name: shuttle\.requests'
kubectl -n starfleet logs deployment/collector --since=30s | grep 'ExplicitBounds #[0-9]*: 0\.25'
kubectl -n starfleet logs deployment/collector --since=30s | grep 'shuttle\.client'
kubectl -n starfleet logs deployment/collector --since=30s | grep 'shuttle\.fuel\.used'
```

Grade it. The check `views` passes.

## Step 4: Make the log queue larger

With a queue of two records the SDK drops log records when the exporter is busy and writes `Queue full, dropping` warnings in the pod log. Set the queue to 2048 records and the batch size to 512:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_BLRP_MAX_QUEUE_SIZE=2048 OTEL_BLRP_MAX_EXPORT_BATCH_SIZE=512
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
```

The batch size cannot be larger than the queue size. Check that log records arrive with a trace ID:

```sh
kubectl -n starfleet logs deployment/collector --since=30s | grep -E 'Trace ID: +[0-9a-f]{32}' | head -n 3
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-02/labs/lab-01
```

All four checks pass. Clean up with `astrona destroy ats-074-lab-050-02`.
