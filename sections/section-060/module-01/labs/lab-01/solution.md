# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-01/labs/lab-01
```

`astrona submit` right after the start shows two checks that already pass once the pods run: `workloads-running` and `collector-received-spans`.

## Step 1: Attach the context in the worker thread

Read the recent `shuttle` lines. A `role=worker` line has `parent_span_id=none`, so the thread did not receive the active context:

```sh
kubectl -n starfleet logs deploy/shuttle --tail=20 | grep '^PROPAGATION'
```

The `shuttle` code calls `context.attach` in the worker only when `SHUTTLE_ATTACH_CONTEXT` is `true`. Set the variable and wait for the new pod:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_ATTACH_CONTEXT=true
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

After a few seconds the new pod logs worker lines with a `parent_span_id` and the same `trace_id` as the client line of that iteration. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-01/labs/lab-01 --keep
```

`context-attached` passes. If it fails, check that the pod is new (`kubectl -n starfleet get pods`) and that the worker lines still show `parent_span_id=none`.

## Step 2: Record a traceparent header

Print the newest `probe` line and copy the value after `traceparent=`:

```sh
kubectl -n starfleet logs deploy/probe --tail=5 | grep '^PROPAGATION' | tail -n 1
```

The value has four fields separated by dashes: version, trace ID, parent ID and trace flags. Split the value and store the four parts:

```sh
TRACEPARENT=$(kubectl -n starfleet logs deploy/probe --tail=5 | grep '^PROPAGATION' | tail -n 1 | sed 's/.* traceparent=\([^ ]*\).*/\1/')
echo "$TRACEPARENT"
kubectl -n starfleet create configmap traceparent-evidence \
  --from-literal=version="$(echo "$TRACEPARENT" | cut -d- -f1)" \
  --from-literal=trace-id="$(echo "$TRACEPARENT" | cut -d- -f2)" \
  --from-literal=parent-id="$(echo "$TRACEPARENT" | cut -d- -f3)" \
  --from-literal=trace-flags="$(echo "$TRACEPARENT" | cut -d- -f4)"
```

The parent ID is the `span_id` of the `shuttle.dispatch` span, because the `shuttle` injects the context of that span. You can confirm it with `kubectl -n starfleet logs deploy/shuttle --tail=20 | grep "$(echo "$TRACEPARENT" | cut -d- -f3)"`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-01/labs/lab-01 --keep
```

All four checks pass. If `traceparent-evidence` fails, the `shuttle` pod may have restarted since you copied the value. Copy a fresh header and create the ConfigMap again.

Clean up:

```sh
astrona destroy ats-074-lab-060-01
```
