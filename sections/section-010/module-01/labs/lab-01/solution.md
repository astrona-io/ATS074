# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you change the environment. The `shuttle` pod needs a few minutes after the start before it sends data.

## Step 1: Read the current resource

Print the environment of the `shuttle` container:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

The output has no `OTEL_SERVICE_NAME`, and `OTEL_RESOURCE_ATTRIBUTES` is `service.version=1.0.0,request.id=ord-4711`. Now read what the Collector received:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -A10 "^Resource attributes" | head -30
```

The block shows a `service.name` that starts with `unknown_service` and a `request.id` attribute.

## Step 2: Set the service name

`OTEL_SERVICE_NAME` is the standard variable for `service.name`. Set it:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_SERVICE_NAME=shuttle
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-01/labs/lab-01 --keep
```

The check `service-name` passes now, because the Deployment sets the name. The check `collector-resource` still fails, because the other attributes are wrong.

## Step 3: Replace the resource attributes

`OTEL_RESOURCE_ATTRIBUTES` is one comma-separated list. Write the complete list, without the request identifier:

```sh
kubectl -n starfleet set env deployment/shuttle "OTEL_RESOURCE_ATTRIBUTES=service.namespace=starfleet,service.version=1.0.0,deployment.environment.name=training"
```

A change to the environment changes the pod template, so Kubernetes starts a new pod. The resource is read when the process starts, so the new pod is the one that sends the new resource. Wait for it:

```sh
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-01/labs/lab-01 --keep
```

The checks `resource-attributes` and `no-request-id` pass now. The check `collector-resource` passes when the Collector log of the last 30 seconds shows the new resource. The check polls for up to two minutes, but the pod must have installed the SDK first.

## Step 4: Confirm in the Collector output

Read the resource again:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -A10 "^Resource attributes" | head -30
```

The block now shows `service.name: Str(shuttle)`, `service.namespace: Str(starfleet)`, `service.version: Str(1.0.0)` and `deployment.environment.name: Str(training)`, and no `request.id`. Run the final grade. All five checks pass:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-01/labs/lab-01
```
