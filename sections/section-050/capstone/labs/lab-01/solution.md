# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/capstone/labs/lab-01
```

The first start takes several minutes because the `shuttle` pod installs the SDK with `pip`.

## Step 1: Read what the SDK reports

Print the start line and the last lines of the pod log:

```sh
kubectl -n starfleet logs deployment/shuttle | grep '\[shuttle\] config'
kubectl -n starfleet logs deployment/shuttle --tail=20
```

The start line shows `sampler=always_off`, queues of 2 and `metric_interval=120000`. The pod log shows export failures that name `collector.starfleet.svc.cluster.local:4319`. The Collector Service has the ports 4317 (OTLP gRPC) and 4318 (OTLP HTTP). The HTTP exporter must use 4318.

## Step 2: Fix the endpoint

Set the endpoint, wait for the new pod and grade it:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/capstone/labs/lab-01 --keep
```

The check `exporter-endpoint` passes. The other checks still fail, because the SDK still has the other settings.

## Step 3: Repair the trace pipeline

The `always_off` sampler records no span. Replace it, and replace the queue of two spans, which drops spans whenever the exporter is busy. The batch size cannot be larger than the queue size:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.25 OTEL_BSP_MAX_QUEUE_SIZE=4096 OTEL_BSP_MAX_EXPORT_BATCH_SIZE=512 OTEL_BSP_SCHEDULE_DELAY=2000
```

## Step 4: Repair the metric pipeline

Set a short interval and delta temporality. Then register the two views. The view `keys` removes the attribute `shuttle.client`, and `drop-fuel` removes the stream `shuttle.fuel.used`:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_METRIC_EXPORT_INTERVAL=5000 OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta SHUTTLE_VIEWS=keys,drop-fuel
```

## Step 5: Repair the log pipeline and the shutdown path

Make the log queue larger, make the script flush on `SIGTERM` and give Kubernetes enough time:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_BLRP_MAX_QUEUE_SIZE=2048 OTEL_BLRP_MAX_EXPORT_BATCH_SIZE=512 SHUTTLE_ON_TERM=shutdown
kubectl -n starfleet patch deployment shuttle --type=merge -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":30}}}}'
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
```

Check the effect in the Collector log. The first command finds the three kinds of telemetry, and the last two print nothing:

```sh
kubectl -n starfleet logs deployment/collector --since=30s | grep -E 'shuttle\.(dock|launch|scan)$|Name: shuttle\.requests|Trace ID' | sort | uniq -c | head
kubectl -n starfleet logs deployment/collector --since=30s | grep 'shuttle\.client'
kubectl -n starfleet logs deployment/collector --since=30s | grep 'shuttle\.fuel\.used'
```

Grade it. The checks `trace-pipeline`, `metric-pipeline`, `log-pipeline` and `shutdown-path` pass.

## Step 6: Record the evidence

Read the values from the running pod and the time:

```sh
pod=$(kubectl -n starfleet get pods -l app=shuttle -o jsonpath='{.items[0].metadata.name}')
kubectl -n starfleet get pod "$pod" -o json | jq -r '.spec.containers[0].env[] | select(.name | test("ENDPOINT|SAMPLER|METRIC_EXPORT_INTERVAL")) | .name + "=" + .value'
date -u +%Y-%m-%dT%H:%M:%SZ
```

Save this as `pipeline-evidence.yaml`, with your own time:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pipeline-evidence
  namespace: starfleet
data:
  endpoint: "http://collector.starfleet.svc.cluster.local:4318"
  sampler: "parentbased_traceidratio"
  sampler-arg: "0.25"
  metric-export-interval-ms: "5000"
  observed-at: "2026-11-03T10:15:00Z"
```

Apply it:

```sh
kubectl apply -f pipeline-evidence.yaml
```

The values must equal the environment of the running pod. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/capstone/labs/lab-01
```

All seven checks pass. Clean up with `astrona destroy ats-074-capstone-050`.
