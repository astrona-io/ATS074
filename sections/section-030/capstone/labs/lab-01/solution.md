# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/capstone/labs/lab-01
```

## Step 1: Read the current configuration

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

You find four faults. `OTEL_SERVICE_NAME=shuttle-test` gives the wrong name. No `OTEL_RESOURCE_ATTRIBUTES` exists. `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://collector:4318` has no path, and a signal-specific endpoint is used as written, so the trace requests go to `/`. The headers hold the token as plain text, and the sampler and the intervals are not set.

## Step 2: Fix the identity and the delivery

Set the name and the attributes, and remove the traces endpoint so that the general endpoint adds `v1/traces`:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_SERVICE_NAME=shuttle OTEL_EXPORTER_OTLP_TRACES_ENDPOINT- OTEL_RESOURCE_ATTRIBUTES="service.namespace=starfleet,deployment.environment.name=production,service.version=3.0.0"
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Wait about a minute and read the resource and the span count:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -E 'service\.|deployment\.|Name +: dock' | sort | uniq -c
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The checks `resource-identity` and `signals-delivered` pass.

## Step 3: Set the sampler and the intervals

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.25 OTEL_BSP_SCHEDULE_DELAY=1000 OTEL_METRIC_EXPORT_INTERVAL=5000
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Grade it: the check `sampler-and-batching` passes.

## Step 4: Move the headers into a Secret

Create the Secret from a literal value. The key must be `otlp-headers`:

```sh
kubectl -n starfleet create secret generic collector-auth --from-literal=otlp-headers='x-starfleet-token=hailing-frequency-7'
```

Replace the plain variable with a reference. A Deployment env entry with `valueFrom` cannot be written with `kubectl set env` and a literal, so patch the Deployment. Save this as `patch-headers.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: shuttle
          env:
            - name: OTEL_EXPORTER_OTLP_HEADERS
              value: null
              valueFrom:
                secretKeyRef:
                  name: collector-auth
                  key: otlp-headers
```

Apply it and wait for the rollout:

```sh
kubectl -n starfleet patch deploy shuttle --patch-file patch-headers.yaml
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Confirm that the Deployment has no plain token:

```sh
kubectl -n starfleet get deploy shuttle -o yaml | grep -c hailing-frequency
```

The count is 0. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/capstone/labs/lab-01
```

All four checks pass. Clean up with `astrona destroy ats-074-capstone-030`.
