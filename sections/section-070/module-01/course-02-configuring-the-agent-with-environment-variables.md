---
draft: true
exam_objectives:
  - Agents
---
# Configuring The Agent With Environment Variables

An agent that you cannot configure from outside would force a rebuild of the image for every change. The Python agent avoids this. It reads standard `OTEL_*` environment variables when the process starts. This part lists the variables that matter, shows the order in which settings win, and changes the settings of a running example. It also explains why every change needs a restart.

## Where the settings come from

The agent reads settings from three places. The first is the command line of `opentelemetry-instrument`. A flag has the name of the property in lowercase with underscores, for example `--traces_exporter console,otlp`. The second is the environment of the process, where the same property is an uppercase variable with the prefix `OTEL_`, for example `OTEL_TRACES_EXPORTER`. The third is the default that the distro or the SDK provides.

A command-line flag overrides the environment variable of the same property. The environment variable overrides the default. On Kubernetes the environment of the container is the natural place, because you can change it with the Deployment and without a new image. The `scout` Deployment uses only environment variables.

## The variables the example uses

Each variable has one job. The first group says where the telemetry goes.

| Variable | What it does |
| --- | --- |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Base address of the OTLP receiver. For HTTP the SDK adds the path of each signal, such as `/v1/traces` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` or `grpc`. It must match the port of the receiver: 4318 for HTTP and 4317 for gRPC |
| `OTEL_TRACES_EXPORTER` | Exporter for spans: `otlp`, `console` or `none` |
| `OTEL_METRICS_EXPORTER` | Exporter for metrics, with the same values |
| `OTEL_LOGS_EXPORTER` | Exporter for log records, with the same values |
| `OTEL_METRIC_EXPORT_INTERVAL` | Time between metric exports, in milliseconds |

The second group says who the telemetry is from.

| Variable | What it does |
| --- | --- |
| `OTEL_SERVICE_NAME` | Sets the resource attribute `service.name` |
| `OTEL_RESOURCE_ATTRIBUTES` | Comma separated `key=value` pairs that become resource attributes |

The third group is specific to the Python agent and controls which libraries are instrumented.

| Variable | What it does |
| --- | --- |
| `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` | Comma separated names of instrumentations to skip, for example `flask` or `requests` |
| `OTEL_PYTHON_EXCLUDED_URLS` | Comma separated regular expressions. A request whose URL matches one is not recorded |

The agent also reads a per-library version of the last variable, such as `OTEL_PYTHON_REQUESTS_EXCLUDED_URLS`, which applies to one library only.

## Why the service name matters

A resource is the set of attributes that describe the entity that produces telemetry. The attribute `service.name` is the most important one. Backends group data by it. If you do not set it, the SDK uses a default that starts with `unknown_service`, and telemetry from many applications gets the same label.

Look at the settings of `scout` and at the resource that reaches the Collector:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get deployment scout -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
```

The list shows `OTEL_SERVICE_NAME=scout`, the attributes `service.namespace=starfleet` and `deployment.environment.name=playground`, and the exporter and endpoint settings. Now look at the resource block in the Collector log:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -E 'service\.(name|namespace)|deployment\.environment' | sort -u
```

The Collector prints the same values as resource attributes. The SDK took them from the two variables. The agent did not guess any of them.

## Changing a setting

Every change goes through the Deployment. Exclude the health check requests first. The kubelet, which is the node agent of Kubernetes, calls `/healthz` every five seconds for the readiness probe. Each call makes a server span that carries no information. Count them now:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -c 'GET /healthz'
```

The count is above zero. Set the excluded URLs and wait for the new pod:

```sh
kubectl -n starfleet set env deployment/scout OTEL_PYTHON_EXCLUDED_URLS=healthz
kubectl -n starfleet rollout status deployment/scout --timeout=420s
```

The pod installs its packages again, so the rollout takes about two minutes. Count again after the new pod has sent a batch:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -c 'GET /healthz'
```

The count is `0`, while `GET /relay` and `GET /dock` keep arriving. The value `healthz` is a regular expression that matches any URL containing that text. A pattern that is too broad, such as `s`, would drop almost every request.

## Why a restart is needed

The agent reads the environment once, in the first step of the start sequence. The instrumentors are patched into the libraries at that moment and the SDK providers are built from the settings of that moment. Nothing in the process watches the environment later. `kubectl set env` changes the Deployment, Kubernetes starts a new pod and the new process reads the new values.

This is a common source of confusion. A change to the ConfigMap `scout-app` has the same rule: the file in the mounted volume changes, but the running process does not read it again.

## Choosing exporters for debugging

The value `console` for an exporter writes the telemetry to the standard output of the application. This helps when the question is whether the application produces the data at all, before you look at the network. The value `none` turns one signal off. With `OTEL_LOGS_EXPORTER=none` the application sends no log records, and a Collector without a logs pipeline then has nothing to refuse.

Use one rule when something is missing: find the first place where the data should appear. If the `console` exporter shows the span, the agent works and the problem is in the transport or in the Collector. If the span is missing there, the problem is in the agent settings or in the coverage of the library.

This part gave you the settings that make one agent fit one service. The next question is what the agent can see at all, and what it has no way to know.

## Common pitfalls

> [!WARNING]
> Changing an environment variable does not change a running process: restart the pod. Do not exclude URLs with a broad pattern. Setting `OTEL_SERVICE_NAME` does not replace `OTEL_RESOURCE_ATTRIBUTES`, and the second variable does not accept spaces around the commas. A protocol that does not match the port (HTTP to 4317, or gRPC to 4318) makes the export fail, and the application keeps running without telemetry.
