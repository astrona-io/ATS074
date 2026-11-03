# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output. Every restart of the `shuttle` pod takes a minute or more, and `astrona submit` waits and checks again for up to about two minutes.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `library-unchanged`. It stays your guard while you fix the service.

## Step 1: Find out why nothing leaves the service

Read the start-up line of the application and the environment of the container:

```sh
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

The line shows `tracer_provider=TracerProvider` and `tracer=NoOpTracer`. The SDK is installed and registered, but it hands out no-op tracers. The environment list shows `OTEL_SDK_DISABLED=true`, which is the reason. No Collector output exists for `starfleet.navigation`:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -c "starfleet.navigation"
```

The count is `0`.

## Step 2: Enable the SDK and set the service name

Remove the variable that disables the SDK, set the service name, and wait for the new pod:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_SDK_DISABLED- OTEL_SERVICE_NAME=shuttle
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

The start-up line now shows `tracer=Tracer`, the SDK tracer class. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-01/labs/lab-01 --keep
```

The checks `sdk-enabled` and `service-name` pass. If `service-name` fails at first, wait a few seconds and submit again, because the Collector needs a new batch from the new pod.

## Step 3: Read the evidence in the Collector log

Look for the scope, the span, the metric and the SDK version in recent output:

```sh
kubectl -n starfleet logs deploy/collector --since=120s | grep -m 8 "service.name\|telemetry.sdk.version\|InstrumentationScope\|plot-course\|shuttle.jumps"
```

You see `service.name: Str(shuttle)`, a `telemetry.sdk.version` line with the version of `opentelemetry-sdk`, the scope `starfleet.navigation` with version `1.0.0`, the span name `plot-course` and the metric name `shuttle.jumps`. The check `telemetry-arrives` passes after this step.

## Step 4: Record the evidence

Read the SDK version and the tracer class again, so that the record holds exactly what you saw:

```sh
kubectl -n starfleet logs deploy/collector --since=120s | grep -m 1 "telemetry.sdk.version"
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
```

Save this as `api-sdk-evidence.yaml`, with the SDK version you read:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-sdk-evidence
  namespace: starfleet
data:
  tracer-class: "Tracer"
  scope-name: "starfleet.navigation"
  telemetry-sdk-version: "1.45.2"
  service-name: "shuttle"
```

Apply it:

```sh
kubectl apply -f api-sdk-evidence.yaml
```

The value of `telemetry-sdk-version` must be exactly what the Collector printed. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-01/labs/lab-01
```

All five checks pass. Clean up with `astrona destroy ats-074-lab-020-01`.
