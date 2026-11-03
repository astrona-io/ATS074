# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes once the pods run: `workloads-running`.

## Step 1: Make the probe extract the trace context

Compare what the `shuttle` sends with what the `probe` records:

```sh
kubectl -n starfleet logs deploy/shuttle --tail=10 | grep '^PROPAGATION'
kubectl -n starfleet logs deploy/probe --tail=10 | grep '^PROPAGATION'
```

The `shuttle` line has a `traceparent=` value, but the `probe` line has `remote=false` and `parent_span_id=none`. The `probe` receives the header and ignores it. Check the environment of the `probe`:

```sh
kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="OTEL_PROPAGATORS")].value}'
```

The `probe` has `OTEL_PROPAGATORS=baggage`, so its propagator reads only the `baggage` header. Set both propagators and wait for the new pod:

```sh
kubectl -n starfleet set env deployment/probe OTEL_PROPAGATORS=tracecontext,baggage
kubectl -n starfleet rollout status deployment/probe --timeout=300s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-02/labs/lab-01 --keep
```

`trace-continued` passes after the `probe` logs a line with `remote=true`.

## Step 2: Remove the credential from baggage

The `baggage` field of the `shuttle` and `probe` lines shows `session-token`. Baggage goes to every service that receives the request, so remove the entry at the source and keep `mission`:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_BAGGAGE=mission=survey
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-02/labs/lab-01 --keep
```

`secret-removed` passes when the newest `shuttle` and `probe` pods log `baggage=mission=survey` and no `session-token`. If it fails, wait a few seconds and submit again, because the check reads the newest lines.

## Step 3: Record the policy

The `shuttle` already sets `OTEL_PROPAGATORS=tracecontext,baggage` and the `probe` now does too. Write the policy:

```sh
kubectl -n starfleet create configmap propagation-policy --from-literal=propagators=tracecontext,baggage --from-literal=baggage-keys=mission
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-02/labs/lab-01 --keep
```

All four checks pass. Clean up:

```sh
astrona destroy ats-074-lab-060-02
```
