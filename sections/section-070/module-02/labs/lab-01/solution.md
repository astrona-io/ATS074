# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Point shuttle at the agent

The SDK in `shuttle` reads `OTEL_EXPORTER_OTLP_ENDPOINT` once at start. Change it and wait for the new pod:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://agent:4318
kubectl -n starfleet rollout status deployment/shuttle --timeout=420s
```

The Service `agent` has `internalTrafficPolicy: Local`, so the request goes to the agent pod on the same node as `shuttle`. On this one-node cluster that is the only agent pod. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-02/labs/lab-01 --keep
```

The check `shuttle-uses-agent` passes.

## Step 2: Add the processors to the agent

Look at the current configuration:

```sh
kubectl -n starfleet get configmap agent-config -o jsonpath='{.data.config\.yaml}'
```

Only `batch` is defined. Save the full ConfigMap as `agent-config.yaml`. The `memory_limiter` goes first so it can refuse data before other work uses memory. The `resourcedetection` processor adds attributes before `batch` groups the data:

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

The running agent still uses the old configuration, because a Collector reads its configuration file once, when it starts. Grade it now and the check `agent-processors` passes, while the next check still fails.

## Step 3: Restart the agent and read the gateway log

Restart the DaemonSet so the new pod loads the file:

```sh
kubectl -n starfleet rollout restart daemonset/agent
kubectl -n starfleet rollout status daemonset/agent --timeout=300s
```

After the next batch, the gateway log shows the attributes the agent added:

```sh
kubectl -n starfleet logs deploy/gateway --since=60s | grep -E 'service.name|host.name|deployment.environment.name'
```

You see `service.name: Str(shuttle)` from the application, and `host.name` and `deployment.environment.name: Str(starfleet-lab)` from the agent. The `env` detector read the second one from `OTEL_RESOURCE_ATTRIBUTES` of the agent container. The `system` detector read the host name of the agent pod.

Grade it. All four checks pass. Clean up with `astrona destroy ats-074-lab-070-02`.
