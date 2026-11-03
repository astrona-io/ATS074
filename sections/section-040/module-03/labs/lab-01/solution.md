# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-03/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you fix the settings. The other checks wait up to about 150 seconds for fresh records, so a submit can take a few minutes.

## Step 1: Give the Resource a service name

List the settings of the `shuttle`:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

The list has the endpoint, the batch delays and the three `SHUTTLE_` switches, but no `OTEL_SERVICE_NAME` and no `OTEL_RESOURCE_ATTRIBUTES`. The SDK reads both when the program builds its Resource, and falls back to an `unknown_service` name when there is no service name. Set both:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_SERVICE_NAME=shuttle OTEL_RESOURCE_ATTRIBUTES=service.version=1.4.0,deployment.environment.name=training
```

Each change to the environment starts a new pod. To save time, you can do all four steps before you wait. Grade this step after the rollout:

```sh
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-03/labs/lab-01 --keep
```

The check `resource-identity` passes when fresh records show `service.name: Str(shuttle)` and `deployment.environment.name: Str(training)`.

## Step 2: Log at INFO

The setting is `SHUTTLE_LOG_LEVEL`. The program sets it on the logger, so a record below the level is never created. Change it:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_LEVEL=INFO
```

Check the Collector after the new pod runs. No record may print `SeverityText: DEBUG`:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -c "SeverityText: DEBUG"
```

The count is `0`. If it is not, the old pod is still running; wait and run the command again. Grade it with `astrona submit` (same command as in step 1). The check `log-level` passes.

## Step 3: Turn off payload logging

The switch is `SHUTTLE_LOG_PAYLOAD`. With the value `true`, the program adds the attributes `request.authorization` and `customer.email` to a record. Turn the switch off:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_PAYLOAD=false
```

Values that were exported before the change stay in the Collector log until it rotates. The check only reads the last 20 seconds. After the rollout, this command prints nothing:

```sh
kubectl -n starfleet logs deploy/collector --since=20s | grep -E "request.authorization|customer.email"
```

Grade it. The check `no-sensitive-data` passes.

## Step 4: Write the error record inside the span

An ERROR record has a trace ID only when it is created while a span is current. The switch `SHUTTLE_LOG_INSIDE_SPAN` is `false`, so the program writes the error after the `with` block of the span has ended. Set it to `true`:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_INSIDE_SPAN=true
```

After the rollout, check that every ERROR record has a trace ID. The `Trace ID` line of an ERROR record is no longer empty:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -A14 "SeverityText: ERROR" | grep "Trace ID"
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-03/labs/lab-01
```

All five checks pass. Clean up with `astrona destroy ats-074-lab-040-03`.
