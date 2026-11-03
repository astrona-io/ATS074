# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you fix the settings. The other checks wait up to about 150 seconds for fresh telemetry, so a submit can take a few minutes. Every change to the environment starts a new pod, so you can make several changes before you wait.

## Step 1: Share one Resource

List the settings of the `shuttle`:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

The list has no `OTEL_SERVICE_NAME` and no `OTEL_RESOURCE_ATTRIBUTES`. The program builds one Resource from these variables and gives it to the tracer provider, the meter provider and the logger provider. One change fixes all three signals:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_SERVICE_NAME=shuttle OTEL_RESOURCE_ATTRIBUTES=service.version=1.4.0,deployment.environment.name=training
```

## Step 2: Keep the traces

The list also shows `OTEL_TRACES_SAMPLER=always_off`. This sampler drops every trace. The spans still have trace IDs, but they are not recorded and not exported. Use a sampler that keeps the traces. `parentbased_always_on` is the SDK default, and `always_on` also works:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_TRACES_SAMPLER=parentbased_always_on
```

## Step 3: Export metrics more often

`OTEL_METRIC_EXPORT_INTERVAL` is `3600000`, one hour in milliseconds. The periodic metric reader exports once per interval, so the first metrics would arrive an hour after the start. Set it to five seconds:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_METRIC_EXPORT_INTERVAL=5000
```

## Step 4: Clean up the logs and write the error inside the span

The `SHUTTLE_` switches control the logs. Set the level to INFO, turn the payload logging off and write the error record while the span is current:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_LEVEL=INFO SHUTTLE_LOG_PAYLOAD=false SHUTTLE_LOG_INSIDE_SPAN=true
```

The error record gets a trace ID only if it is written inside the span. Because the sampler now keeps the traces, the span is exported too, so the ID joins the record to a real span.

## Step 5: Wait and verify the join yourself

Wait for the new pod. Then take the trace ID of one ERROR record and search for it:

```sh
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
TRACE_ID=$(kubectl -n starfleet logs deploy/collector --since=45s | awk '/SeverityText: ERROR/{f=1} f && /Trace ID:/{print $3; exit}')
kubectl -n starfleet logs deploy/collector --since=60s | grep -A3 -E "Trace ID *: *$TRACE_ID"
```

The search shows the log record and the span `dispatch` with the same trace ID. Check the metric too:

```sh
kubectl -n starfleet logs deploy/collector --since=40s | grep "shuttle.dispatch.count"
```

Grade the lab:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/capstone/labs/lab-01
```

All six checks pass. Clean up with `astrona destroy ats-074-capstone-040`.
