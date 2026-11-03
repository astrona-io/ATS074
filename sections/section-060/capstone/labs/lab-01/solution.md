# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes once the pods run: `workloads-running`.

## Step 1: Set the propagators on both services

Read the log lines first. The `shuttle` client line has `traceparent=none`, because its propagator list is only `baggage`. The `probe` has the same list, so it would ignore a `traceparent` header anyway. Fix both with the standard variable:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_PROPAGATORS=tracecontext,baggage
kubectl -n starfleet set env deployment/probe OTEL_PROPAGATORS=tracecontext,baggage
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/capstone/labs/lab-01 --keep
```

`propagators-configured` passes at once, because it reads the Deployments. `trace-continued` passes after both new pods run and the `probe` logs `remote=true`.

## Step 2: Attach the context in the worker thread

Worker lines still show `parent_span_id=none`. A new thread starts with an empty context, and the `shuttle` attaches the captured context only when the variable is `true`:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_ATTACH_CONTEXT=true
```

## Step 3: Remove the credential and allow one baggage key

Send only `mission` and let the `probe` turn only `mission` into a span attribute:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_BAGGAGE=mission=survey
kubectl -n starfleet set env deployment/probe PROBE_BAGGAGE_ATTRIBUTES=mission
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
kubectl -n starfleet rollout status deployment/probe --timeout=300s
```

Each `set env` starts a new rollout, so the pods may restart more than once. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/capstone/labs/lab-01 --keep
```

`trace-continued`, `context-attached`, `secret-removed` and `baggage-attribute-allowlist` pass when the new pods log fresh lines and the collector shows `baggage.mission`.

## Step 4: Record the report

Choose a trace ID from a `probe` line with `remote=true` that is old enough for the `shuttle` worker line and the collector to have it:

```sh
kubectl -n starfleet logs deploy/probe --tail=10 | grep '^PROPAGATION' | grep ' remote=true '
```

Take the `trace_id` of the second newest line. Check that it is in the `shuttle` log and the collector log, then create the report:

```sh
TRACE_ID=<trace id from the probe line>
kubectl -n starfleet logs deploy/shuttle --tail=40 | grep "$TRACE_ID"
kubectl -n starfleet logs deploy/collector | grep -c "$TRACE_ID"
kubectl -n starfleet create configmap propagation-report --from-literal=trace-id="$TRACE_ID" --from-literal=propagators=tracecontext,baggage --from-literal=baggage-keys=mission
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/capstone/labs/lab-01 --keep
```

All seven checks pass. If `propagation-report` fails, pick a trace ID from a more recent `probe` line, because the `shuttle` pod may have restarted since. Clean up:

```sh
astrona destroy ats-074-capstone-060
```
