# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Configure the agent settings of scout

Two layers are involved. The instrumentation agent in the `scout` process (`opentelemetry-instrument`) reads `OTEL_*` variables. The Collector agent (the DaemonSet) reads its own file. Start with the application. Read its environment:

```sh
kubectl -n starfleet get deployment scout -o json | jq '.spec.template.spec.containers[0].env'
```

You see `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=flask` and the endpoint `http://gateway:4318`. Fix all four settings with one command. The trailing minus sign deletes a variable:

```sh
kubectl -n starfleet set env deployment/scout OTEL_PYTHON_DISABLED_INSTRUMENTATIONS- OTEL_EXPORTER_OTLP_ENDPOINT=http://agent:4318 OTEL_SERVICE_NAME=scout OTEL_PYTHON_EXCLUDED_URLS=healthz
```

The change starts a rollout. Wait for it, because the new pod installs its packages first:

```sh
kubectl -n starfleet rollout status deployment/scout --timeout=420s
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/capstone/labs/lab-01 --keep
```

The check `scout-agent-configured` passes.

## Step 2: Add the processors to the Collector agent

Save the whole ConfigMap as `agent-config.yaml`. `memory_limiter` is first so it can refuse data early. `resourcedetection` adds `host.name` (the `system` detector) and the attribute from the agent environment (the `env` detector). `batch` is last:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: agent-config
  namespace: starfleet
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:
      memory_limiter:
        check_interval: 1s
        limit_mib: 160
        spike_limit_mib: 40
      resourcedetection:
        detectors: [env, system]
        timeout: 2s
        override: false
      batch:
        timeout: 5s
    exporters:
      otlp:
        endpoint: gateway:4317
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, resourcedetection, batch]
          exporters: [otlp]
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, resourcedetection, batch]
          exporters: [otlp]
```

Apply it:

```sh
kubectl apply -f agent-config.yaml
```

Grade it. The check `agent-processors` passes. The running agent still has the old configuration.

## Step 3: Remove the host mount from the agent

The agent mounts `/var/log` from the node, but it only receives OTLP. Its receivers need no host file. A mounted host directory lets a bug or a changed configuration read files of every pod on the node. Find the volume:

```sh
kubectl -n starfleet get daemonset agent -o json | jq '.spec.template.spec | {volumes, mounts: .containers[0].volumeMounts}'
```

The volume `hostlogs` and its mount are the second entries of each list. Remove both with one patch:

```sh
kubectl -n starfleet patch daemonset agent --type=json -p '[{"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/1"},{"op":"remove","path":"/spec/template/spec/volumes/1"}]'
```

The patch changes the pod template, so the DaemonSet replaces its pod. Grade it. The check `agent-least-authority` passes.

## Step 4: Restart the agent and read the gateway log

The patch already replaced the agent pod, and the new pod read the new ConfigMap. If you applied the ConfigMap after the patch, restart the DaemonSet once more to be sure:

```sh
kubectl -n starfleet rollout restart daemonset/agent
kubectl -n starfleet rollout status daemonset/agent --timeout=300s
```

Wait about a minute, then read what arrives at the gateway:

```sh
kubectl -n starfleet logs deploy/gateway --since=40s | grep -E 'service.name|host.name|deployment.environment.name|Name +: GET'
```

You see `GET /relay` and `GET /dock`, the resource attributes of the application and the two attributes added by the agent. No `GET /healthz` line remains. Grade it. All five checks pass. Clean up with `astrona destroy ats-074-capstone-070`.
