---
draft: true
exam_objectives:
  - Agents
---
# Authority And Shared-Host Data Risks

Putting a Collector next to the workloads brings convenience and also brings access. A node-level agent can see things that no single application can see, and so can anyone who can reach its ports. This part lists what gives an agent its authority, what data an agent can expose or accept from others, and which settings reduce the risk. The examples use the playground agent.

## Authority comes from the pod spec

A container in Kubernetes can do what its pod specification allows. An agent that needs only to receive OTLP and to send it on needs a ConfigMap and a network port. Anything beyond that is added authority, and each addition has a reason in some configuration and a cost in the case of a bug or an attack.

The main sources of authority are:

- `hostPath` volumes mount a directory of the node into the container. A mount of `/var/log` exposes the container logs of every pod on the node.
- `hostNetwork: true` puts the pod in the network namespace of the node, so its ports are node ports.
- `privileged: true` removes most limits of the container runtime.
- `hostPort` publishes a container port on the node address.
- A service account with Kubernetes API permissions, which some processors and receivers need to read pod metadata.

Receivers decide which of these an agent needs. The `otlp` receiver needs none. The `filelog` receiver reads log files, so it needs the directory with those files. The `hostmetrics` receiver reads host statistics, which needs access to the host process and file system views.

## Check what your agent has

Read the pod template of the playground agent:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get daemonset agent -o json | jq '.spec.template.spec | {hostNetwork, volumes, securityContext: .containers[0].securityContext}'
```

The `hostNetwork` field is `null`, the only volume is the ConfigMap `agent-config` and the container has no security context. This agent has the least authority that works: it can read its own configuration and nothing else from the node.

Now think about an agent that someone gave a log mount for convenience: a `hostPath` volume for `/var/log` on the node, mounted into the container at `/host/var/log`. The playground agent does not have it. With such a mount, a `filelog` receiver can read `/host/var/log/pods/*/*/*.log`. These files hold the standard output of every container on the node, including the containers of other teams. A mistake in the receiver path, or a vulnerability in the Collector, now reaches that content. The Collector itself does not know which pod belongs to which team: it reads the files it is allowed to read.

## The agent port is open to the whole cluster

The `otlp` receiver of the playground agent listens on `0.0.0.0:4318`, which means on every network interface of the pod. The Service `agent` forwards cluster traffic to it. Any pod that can reach the Service can send telemetry, and the Collector does not ask who sent it. A sender can use any `service.name`.

Show it. Save this as `fake-span.json`:

```json
{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"impostor"}}]},"scopeSpans":[{"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"fake-span","kind":1,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}
```

Send it from the `shuttle` pod to the agent. The `shuttle` image is Python, so the command uses the standard library:

```sh
kubectl -n starfleet exec -i deploy/shuttle -- python -c "import sys, urllib.request as u; r = u.Request('http://agent:4318/v1/traces', sys.stdin.buffer.read(), {'Content-Type': 'application/json'}); print(u.urlopen(r).status)" < fake-span.json
```

The command prints `200`. After the next batch, the gateway log shows a span `fake-span` with `service.name: Str(impostor)`:

```sh
kubectl -n starfleet logs deploy/gateway --since=60s | grep -B 12 'fake-span' | grep -E 'service.name|Name +:'
```

The agent accepted the span, added host attributes to it and forwarded it as if it were real. A backend cannot tell this span from a true one. The controls for this are on the network and in the Collector: a NetworkPolicy that limits who may reach the receiver port, TLS and authentication on the receiver for traffic that leaves a trusted pod, and rules at the gateway that drop or label data from unexpected sources.

## Attribution on a shared agent

A DaemonSet agent serves all pods on a node, and the data of many teams passes through one process. Resource identity must stay separate. The application should set `service.name` and `service.namespace`, and the agent should add the facts about the host, not replace the facts about the service. The `override: false` setting of `resourcedetection` follows this rule. A processor that adds Kubernetes metadata, such as the pod name and namespace, needs permission to read pods through the Kubernetes API. That permission is more authority, so give it a Role limited to what the processor needs.

Without clean attribution, a dashboard shows data of two services under one label, or a host attribute hides the real source. The faults look like application bugs and take long to find.

## Sensitive data in telemetry

Telemetry can hold data that was never meant for an observability backend. Span attributes can carry a user name, a query text or a token that an application put into an HTTP header or a URL. Logs read from files can carry anything the application printed. The agent sits where the data is still close to the source and cheap to change, so it is a good place for controls:

- Do not read more files than the use case needs. Choose receivers by the data you want, not by what the mount allows.
- Remove or hash sensitive attributes with processors before the data leaves the node. This is a Collector setting, and it applies to everything that passes.
- Use encrypted transport between tiers. The playground sets `tls: insecure: true` on the exporter to keep the example short. A real agent-to-gateway link should use TLS.
- Keep credentials for the backend at the gateway and not on every node. A leak on one node then does not hand out the credentials.

## Reducing the exposure step by step

Work from the pod spec outward. Each step removes one kind of reach, and each step can be checked with a command.

1. List the receivers in the configuration and write down the file, network or API access each one needs.
2. Compare that list with the volumes, host settings and service account of the DaemonSet. Remove everything that no receiver uses.
3. Bind the receiver to the address that clients really use. A receiver on `localhost` is not reachable from other pods, which is right for a sidecar and wrong for a DaemonSet.
4. Add a NetworkPolicy that allows only the namespaces that must send telemetry.
5. Turn on TLS for the link to the next tier and keep backend credentials at the gateway.

The order follows the size of the risk: a host mount is worse than an open port, and an open port is worse than a missing certificate on one internal hop.

## Failure and capacity

The agent is a shared dependency. If it is overloaded or down, every application on the node is affected in the same way, according to the buffering in each SDK. The `memory_limiter` protects the node from the agent, and the resource requests and limits of the pod protect the agent from the node. Size the limits from measured volumes, and test what the applications do when the agent refuses data.

You now have the full picture of an agent: what it is, what it runs and what it may touch. The common rule is to give the agent only the access its receivers need, and to treat its open port as an input that anyone in reach can use.

## Common pitfalls

> [!WARNING]
> Do not mount host directories, enable `hostNetwork` or run `privileged` for an agent that only receives OTLP. A node-level agent that reads log files exposes the output of every pod on the node. An open receiver port accepts data from any pod and trusts the `service.name` it carries. `tls: insecure: true` is for an example only. Do not let the agent overwrite the service identity that the application set.
