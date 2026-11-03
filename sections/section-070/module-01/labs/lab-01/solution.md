# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you change the environment.

## Step 1: Switch the Flask instrumentation back on

Read the environment of the `scout` container:

```sh
kubectl -n starfleet get deployment scout -o json | jq '.spec.template.spec.containers[0].env'
```

The list has `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` with the value `flask`. The agent reads this variable when it starts and skips the listed instrumentation libraries. Remove the variable. A trailing minus sign deletes an environment variable:

```sh
kubectl -n starfleet set env deployment/scout OTEL_PYTHON_DISABLED_INSTRUMENTATIONS-
kubectl -n starfleet rollout status deployment/scout --timeout=420s
```

Wait for the rollout. The new pod installs its packages again. Then look for server spans:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -E 'Name +: GET /(relay|dock)'
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-01/labs/lab-01 --keep
```

The check `flask-instrumentation-enabled` passes.

## Step 2: Give scout a service identity

The agent cannot guess the service name. It reports `unknown_service` until `OTEL_SERVICE_NAME` is set. Set the name and the namespace in one command:

```sh
kubectl -n starfleet set env deployment/scout OTEL_SERVICE_NAME=scout OTEL_RESOURCE_ATTRIBUTES=service.namespace=starfleet
kubectl -n starfleet rollout status deployment/scout --timeout=420s
```

When the new pod is ready, the Collector log shows `service.name: Str(scout)` in the resource block of each batch:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -E 'service\.(name|namespace)'
```

Grade it. The check `service-identity` passes.

## Step 3: Exclude the health check path

`OTEL_PYTHON_EXCLUDED_URLS` holds regular expressions. The instrumentation skips every request whose URL matches one of them. Set it, wait for the rollout and count the health check spans in the last minute:

```sh
kubectl -n starfleet set env deployment/scout OTEL_PYTHON_EXCLUDED_URLS=healthz
kubectl -n starfleet rollout status deployment/scout --timeout=420s
kubectl -n starfleet logs deploy/collector --since=40s | grep -c 'GET /healthz'
```

The count is `0` once the old pod is gone and the new pod has sent its first batch. The `GET /relay` and `GET /dock` spans keep arriving, because only matching URLs are skipped.

Grade it. All four checks pass. Clean up with `astrona destroy ats-074-lab-070-01`.
