# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output. Every restart of the `shuttle` pod takes a minute or more, and `astrona submit` waits and checks again for up to about two minutes.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `library-unchanged`. It stays your guard while you fix the service.

## Step 1: Read the current state

List the environment of the container and the start-up line and loop lines of the application:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
kubectl -n starfleet logs deploy/shuttle --tail=3
```

The environment shows six problems. `SHUTTLE_CONFIGURE_SDK=false` means the application never builds the SDK. There is no `OTEL_SERVICE_NAME`. The endpoint uses port 4317. `SHUTTLE_SPAN_PROCESSORS=simple`. `OTEL_TRACES_SAMPLER=always_off`. `OTEL_PROPAGATORS=none`. The start-up line shows `tracer=ProxyTracer`, which is an API class, and the loop lines show an empty list of injected headers.

## Step 2: Register the SDK, name the service and fix the endpoint

Change the first three settings and wait for the new pod. The environment attribute stays, because you do not touch `OTEL_RESOURCE_ATTRIBUTES`:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_CONFIGURE_SDK=true OTEL_SERVICE_NAME=shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

The start-up line now shows `tracer=Tracer`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/capstone/labs/lab-01 --keep
```

The checks `sdk-registered`, `resource` and `export-path` pass. Spans do not arrive yet, because the sampler drops them, but metrics and log records do.

## Step 3: Fix the processors, the sampler and the propagators

Set the processor list and the sampler, and remove the variable that switches propagation off. One change means one restart:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_SPAN_PROCESSORS=crew-tag,batch OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.5 OTEL_PROPAGATORS-
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
kubectl -n starfleet logs deploy/shuttle --tail=3
```

The start-up line shows `processors=crew-tag,batch` and a sampler description that holds `TraceIdRatioBased{0.5}`. The loop lines show `injected headers: ['traceparent']`. Grade it: the checks `processors-and-sampler` and `propagation` pass. About half of the traces are kept, so the first spans can take a few extra seconds.

## Step 4: Read the evidence

Read the values you must record:

```sh
kubectl -n starfleet logs deploy/collector --since=120s | grep -m 1 "telemetry.sdk.version"
kubectl -n starfleet logs deploy/collector --since=120s | grep -m 1 "deployment.environment.name"
```

The first line shows the version of `opentelemetry-sdk`. The second shows `Str(staging)`.

## Step 5: Record the evidence

Save this as `composability-evidence.yaml`, with the SDK version you read:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: composability-evidence
  namespace: starfleet
data:
  tracer-class: "Tracer"
  injected-headers: "traceparent"
  telemetry-sdk-version: "1.45.2"
  environment: "staging"
```

Apply it:

```sh
kubectl apply -f composability-evidence.yaml
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/capstone/labs/lab-01
```

All seven checks pass. Clean up with `astrona destroy ats-074-capstone-020`.
