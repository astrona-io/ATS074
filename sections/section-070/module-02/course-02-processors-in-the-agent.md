---
draft: true
exam_objectives:
  - Agents
---
# Processors In The Agent

A receiver and an exporter are enough to move data, but an agent that only moves data does little to protect the node or to describe the data. Processors do this work. An agent usually needs three: `memory_limiter`, `resourcedetection` and `batch`. This part explains what each one does, why their order in the pipeline matters, and how to see their effect at the gateway.

## How a pipeline runs the processors

A processor receives data from the previous component of the pipeline, changes it and hands it to the next one. The list in `processors: [...]` is the order of execution. The Collector builds a separate instance of each processor for each pipeline that names it, so the traces pipeline and the metrics pipeline do not share state.

The playground agent has this configuration for traces, and the same list for metrics:

```yaml
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, batch]
      exporters: [otlp]
```

A processor is defined once in the `processors` section and only runs when a pipeline lists it. A processor that is defined but not listed does nothing, and the Collector does not warn about this.

## memory_limiter: protect the process

The `memory_limiter` processor stops the Collector from using more memory than the container can give. It measures the memory use of the process at an interval and compares it with two limits.

- `check_interval` is the time between measurements. One second is a common value. A longer interval lets a burst grow between two checks.
- `limit_mib` is the hard limit, in mebibytes, for the memory of the Collector process. The real process size is typically larger than this number by some tens of mebibytes.
- `spike_limit_mib` is the headroom for growth between two checks. The soft limit is `limit_mib` minus `spike_limit_mib`.

Above the soft limit, the processor refuses new data and returns a retryable error to the component before it, which is the receiver. Above the hard limit, it also forces garbage collection. The playground uses a limit of 160 MiB, a spike limit of 40 MiB (so the soft limit is 120 MiB) and a container limit of 256 MiB. The container limit must be larger than the hard limit plus the usual overhead, or Kubernetes kills the pod before the processor acts.

Refusing data is only safe when the sender retries. The OTLP exporters in the SDKs retry retryable errors, so a refused export is sent again later. A sender that does not retry loses the data. The processor also lets the Collector use a percentage of the available memory instead of a fixed number, which fits containers, where the limit comes from the cgroup of the pod.

## Why memory_limiter goes first

The documentation advises placing `memory_limiter` first in every pipeline. The reason is the direction of the refusal. When the first processor refuses, the error goes back to the receiver, which can tell the sender to wait. When it sits later in the list, the earlier processors have already used memory on data that is then refused. Putting it first stops the growth at the entrance.

## resourcedetection: say where the data came from

The `resourcedetection` processor adds resource attributes that it finds in the environment of the Collector. Each name in `detectors` is one source.

- `env` reads the environment variable `OTEL_RESOURCE_ATTRIBUTES`, a comma separated list of `key=value` pairs.
- `system` asks the operating system. It adds the host name as `host.name` and related attributes such as the operating system type.
- Other detectors read cloud or container platform metadata, for example for a cloud provider or Docker.

If two detectors set the same attribute, the detector that comes first in the list wins. The setting `override` decides what happens when the data already has an attribute of the same name. Its default is `true`, so the detected value replaces the existing one. The playground sets `override: false`, so the value from the application stays. The setting `timeout` limits how long detection may take.

## What the system detector really sees

The agent runs in a container. The `system` detector reports the host name that the process sees, and inside a pod this is the name of the agent pod, not the name of the node. If you need the node name, add it through the environment, for example with the Kubernetes downward API into `OTEL_RESOURCE_ATTRIBUTES`, or use a detector or processor for Kubernetes metadata. The attribute is correct, but it answers a different question than people expect.

Read the effect at the gateway. First the attributes from the application and the agent:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet logs deploy/gateway --since=60s | grep -E 'service\.(name|namespace)|host\.name|deployment\.environment' | sort -u
```

The values `service.name` and `service.namespace` come from the application. The values `host.name` and `deployment.environment.name` come from the agent. The agent container has the environment variable `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=starfleet-lab`, which the `env` detector turned into a resource attribute. Check the variable:

```sh
kubectl -n starfleet get daemonset agent -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

Now remove one processor from the effect. First print the current configuration:

```sh
kubectl -n starfleet get configmap agent-config -o jsonpath='{.data.config\.yaml}'
```

Edit the ConfigMap with `kubectl -n starfleet edit configmap agent-config` and remove `resourcedetection` from both `processors` lists. Do not remove the definition, only the list entries. Then restart the agent, because the Collector reads its configuration only when it starts:

```sh
kubectl -n starfleet rollout restart daemonset/agent
```

After about 30 seconds, the gateway log no longer shows `host.name` and `deployment.environment.name` for new data. The data is the same, but it has lost its description of the source. Restore the lists with `kubectl edit` and restart the agent again.

## batch: send fewer, larger requests

The `batch` processor collects data and sends it in groups. It has three settings. `timeout` is the longest wait before a group is sent, and the default is 200 ms. `send_batch_size` is the item count that triggers a send, and the default is 8192 spans, data points or log records. `send_batch_max_size` is a hard upper limit for a group, and the default of 0 means no limit.

Larger groups mean fewer network requests and better compression. They also mean more memory in the Collector and more delay. The playground uses `timeout: 5s` and a size of 512, which fits a small example. `batch` goes last because the earlier processors should change the data before it is grouped.

## What the three do together

For one span, the order is: the `otlp` receiver accepts it, `memory_limiter` checks the memory state and may refuse it, `resourcedetection` adds the host and environment attributes, `batch` groups it, and the `otlp` exporter sends the group to the gateway. Each step has one reason, and each reason is about the node: protect memory, describe the source, reduce requests.

You now can read and write the agent pipeline. The remaining question is what the agent is allowed to touch, because a Collector placed on a shared node can reach more than telemetry.

## Common pitfalls

> [!WARNING]
> A Collector does not reload its configuration file: restart the pod after every change of the ConfigMap. Do not put `memory_limiter` after `batch`, and keep the container memory limit above the hard limit of the processor. A processor that is defined but not listed in a pipeline does nothing. The `system` detector reports the host name of the pod, not of the node. With `override: true`, the agent replaces attributes that the application set.
