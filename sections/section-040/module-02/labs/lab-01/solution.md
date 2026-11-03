# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-02/labs/lab-01
```

## Step 1: Set the export interval and the temporality

The SDK reads two environment variables when the program starts. `OTEL_METRIC_EXPORT_INTERVAL` is the time in milliseconds between two exports of the periodic metric reader. `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` selects the temporality of the OTLP exporter. The value `delta` makes counters and histograms report the change since the last export. Up-down counters stay cumulative.

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_METRIC_EXPORT_INTERVAL=10000 OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

`kubectl set env` changes the pod template, so Kubernetes starts a new pod. Check the two values on the Deployment:

```sh
kubectl -n starfleet get deploy shuttle -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-02/labs/lab-01 --keep
```

The check `export-settings` passes.

## Step 2: Define the View

A `View` changes how the SDK aggregates one instrument. `attribute_keys` keeps only the listed attributes, so `request.id` is dropped and measurements with the same route and status merge into one series. `ExplicitBucketHistogramAggregation` sets the bucket boundaries. Save this as `configmap-shuttle-views.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: shuttle-views
  namespace: starfleet
data:
  views.py: |
    from opentelemetry.sdk.metrics.view import ExplicitBucketHistogramAggregation, View

    VIEWS = [
        View(
            instrument_name="shuttle.request.duration",
            attribute_keys={"http.route", "http.response.status_code"},
            aggregation=ExplicitBucketHistogramAggregation(
                boundaries=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0)
            ),
        ),
    ]
```

Apply it:

```sh
kubectl apply -f configmap-shuttle-views.yaml
```

Then check the result:

```sh
kubectl -n starfleet get configmap shuttle-views -o jsonpath='{.data.views\.py}'
```

Grade it. The check `views-configured` passes. The live checks still fail, because the running pod imported the old empty list when it started.

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-02/labs/lab-01 --keep
```

## Step 3: Restart the program and read the Collector log

The program imports `views.py` once. Restart the Deployment so that the new pod reads the new file:

```sh
kubectl -n starfleet rollout restart deploy/shuttle
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

The new pod installs the SDK first, so wait about two minutes. Then print the histogram from the Collector log:

```sh
kubectl -n starfleet logs deploy/collector --since=45s | awk '/^Metric #/ {show=0} /-> Name: shuttle.request.duration/ {show=1} show' | head -40
```

You should see `AggregationTemporality: Delta`, data point attributes `http.route` and `http.response.status_code` without `request.id`, and `ExplicitBounds` lines that start at `0.010000`. If the log is empty, wait ten seconds and run it again. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-02/labs/lab-01
```

All four checks pass. Clean up with `astrona destroy ats-074-lab-040-02`.
