# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-02/labs/lab-01
```

## Step 1: Fix the endpoint and the sampler

Print the environment of the Deployment:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

The endpoint is `http://collector:4317`. The service has only the HTTP exporter, and port 4317 is the gRPC listener of the Collector, so every export fails. The HTTP listener is port 4318. The sampler is `always_off`, which records no span, so a correct endpoint alone brings no spans. Fix both:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318 OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.5
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Wait about a minute and count the spans that reach the Collector:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -Ec 'Name +: dock'
```

The count is greater than zero. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-02/labs/lab-01 --keep
```

The checks `traces-delivered` and `sampler-configuration` pass.

## Step 2: Shorten the metric interval

The Deployment sets `OTEL_METRIC_EXPORT_INTERVAL=600000`, which is ten minutes in milliseconds. The first metric export comes after ten minutes. Set five seconds:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_METRIC_EXPORT_INTERVAL=5000
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
sleep 30; kubectl -n starfleet logs deploy/collector --since=30s | grep -E 'Name: +shuttle.docks' | head -2
```

You should see the metric name. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-02/labs/lab-01
```

All three checks pass. Clean up with `astrona destroy ats-074-lab-030-02`.
