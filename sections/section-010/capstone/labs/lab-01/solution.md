# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you change the Deployment. The `shuttle` pod needs a few minutes after the start before it sends data.

## Step 1: Read the starting state

Print the environment of the `shuttle` container and the resource that the Collector receives:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
kubectl -n starfleet logs deploy/collector --since=20s | grep -A10 "^Resource attributes" | head -24
```

The environment has no `OTEL_SERVICE_NAME`, and `OTEL_RESOURCE_ATTRIBUTES` holds `service.version=1.0.0` and `request.id=ord-4711`. It has no temporality setting, and `OTEL_METRICS_EXEMPLAR_FILTER` is `always_off`. The Collector shows a service name that starts with `unknown_service`.

## Step 2: Fix the resource

`OTEL_SERVICE_NAME` sets `service.name`. `OTEL_RESOURCE_ATTRIBUTES` replaces the whole attribute list, so write every attribute you want to keep and leave out `request.id`:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_SERVICE_NAME=shuttle "OTEL_RESOURCE_ATTRIBUTES=service.namespace=starfleet,service.version=1.0.0,deployment.environment.name=training"
```

Do not wait for the rollout yet. Each `set env` changes the pod template and starts a new pod, so set the metric variables in the next step first.

## Step 3: Fix the metric settings

Ask for delta temporality and allow exemplars for measurements inside a sampled span, then wait for the new pod:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta OTEL_METRICS_EXEMPLAR_FILTER=trace_based
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

The resource and the metric provider read their variables when the process starts, so the final pod uses all of the new values. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/capstone/labs/lab-01 --keep
```

The checks `service-identity` and `metrics-configured` pass now. The check `collector-all-signals` passes when the last 40 seconds of the Collector log show the new resource, a delta sum, an exemplar and a log record with a trace ID. It polls for up to two minutes.

## Step 4: Read the values for the record

Read the resource, the temporality and the unit from the Collector output, not from your own settings:

```sh
kubectl -n starfleet logs deploy/collector --since=20s | grep -A12 "^Resource attributes" | head -16
kubectl -n starfleet logs deploy/collector --since=20s | grep -A6 "Name: shuttle.requests" | grep "AggregationTemporality" | head -1
kubectl -n starfleet logs deploy/collector --since=20s | grep -A4 "Name: shuttle.request.duration" | grep "Unit" | head -1
```

The resource shows the four attributes, the sum shows `Delta` and the unit is `s`.

## Step 5: Write the record

Save this as `configmap-data-model-record.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: data-model-record
  namespace: starfleet
data:
  service-identity: "service.name=shuttle service.namespace=starfleet service.version=1.0.0 deployment.environment.name=training"
  temporality: "delta"
  duration-unit: "s"
```

Apply it:

```sh
kubectl apply -f configmap-data-model-record.yaml
```

Run the final grade. All five checks pass:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/capstone/labs/lab-01
```
