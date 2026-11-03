# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you fix the application.

## Step 1: Read the starting state

Read the environment of the `shuttle` container and the end of the Collector log:

```sh
kubectl -n starfleet get deployment shuttle -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
kubectl -n starfleet logs deploy/collector --tail=20
```

The environment has no `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES` has only `service.version=1.0.0`, and `OTEL_TRACES_SAMPLER` is `traceidratio` with `OTEL_TRACES_SAMPLER_ARG` set to `0`. That sampler keeps no trace, so the Collector log has no span of the `shuttle`.

## Step 2: Fix the sampler and the identity

Change all of it with one command. The trailing `-` removes the sampler argument, which `parentbased_always_on` does not use. Replacing the pod takes a few minutes because the new pod installs the SDK again:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_SERVICE_NAME=shuttle OTEL_RESOURCE_ATTRIBUTES=service.version=1.0.0,deployment.environment.name=lab OTEL_TRACES_SAMPLER=parentbased_always_on OTEL_TRACES_SAMPLER_ARG-
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Wait until the application prints `trace 1 finished`:

```sh
kubectl -n starfleet logs deploy/shuttle --tail=5
```

Then read the Collector. Look for `service.name: Str(shuttle)` and `deployment.environment.name: Str(lab)` in the resource attributes, and for the three span names:

```sh
kubectl -n starfleet logs deploy/collector --since=60s
```

The `scan` and `report` spans have a `Parent ID` equal to the `ID` of the `dock` span in the same trace. The `dock` span has an empty `Parent ID`, which marks it as the root. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-01/labs/lab-01 --keep
```

The checks `service-name`, `environment-attribute`, `sampler-keeps-traces` and `parent-child-recorded` pass. `failure-recorded` still fails.

## Step 3: Record the exception and the error status

Find the failed `report` span in the Collector log. Its `Status code` is `Unset` and it has no `Events:` section. Open the application code:

```sh
kubectl -n starfleet get configmap shuttle-app -o jsonpath='{.data.app\.py}'
```

The `report` span is started with `record_exception=False` and `set_status_on_exception=False`. Those two arguments of `start_as_current_span` switch off the default behavior: with the defaults, an exception that leaves the `with` block is added to the span as an `exception` event and sets the status to `Error`. Remove both lines:

```sh
kubectl -n starfleet edit configmap shuttle-app
```

Restart the Deployment so the pod reads the new file, and wait:

```sh
kubectl -n starfleet rollout restart deployment/shuttle
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Every third trace fails. After the application has printed `trace 3 finished`, read the Collector log again. The `report` span of the failed trace has `Status code    : Error` and a `SpanEvent` with `-> Name: exception`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-01/labs/lab-01
```

All six checks pass. Clean up with `astrona destroy ats-074-lab-040-01`.
