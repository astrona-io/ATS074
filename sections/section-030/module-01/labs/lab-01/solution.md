# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-01/labs/lab-01
```

## Step 1: Enable the SDK

Print the environment of the Deployment:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

`OTEL_SDK_DISABLED=true` selects a no-op SDK, so nothing is recorded or exported. Remove the variable. The trailing minus sign deletes it:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_SDK_DISABLED-
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-01/labs/lab-01 --keep
```

The check `sdk-enabled` passes.

## Step 2: Fix the service name

The Deployment sets `OTEL_SERVICE_NAME=shuttle-test`. That variable wins over any `service.name` in `OTEL_RESOURCE_ATTRIBUTES`, so the value `shuttle` in the list never applies. Set the dedicated variable to the right name:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_SERVICE_NAME=shuttle
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Wait about a minute for the new pod to export, then read the resource at the Collector:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep 'service.name' | sort -u
```

You should see `service.name: Str(shuttle)`. Grade it: the check `service-name` passes.

## Step 3: Repair the resource attributes

The list in `OTEL_RESOURCE_ATTRIBUTES` separates two pairs with a semicolon, and it contains `service.name`, `staging` and an old version. Replace the whole value with comma-separated pairs. Keep the quotes, because the value contains commas:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_RESOURCE_ATTRIBUTES="service.namespace=starfleet,deployment.environment.name=production,service.version=2.4.1"
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Wait for fresh telemetry and read the attributes:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -E 'service\.|deployment\.' | sort -u
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-01/labs/lab-01
```

All three checks pass. Clean up with `astrona destroy ats-074-lab-030-01`.
