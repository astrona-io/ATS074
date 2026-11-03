---
draft: true
exam_objectives:
  - Agents
---
# Summary

The Collector has no built-in role. An agent is a Collector placed close to the applications: as a sidecar in the pod or as a DaemonSet with one pod per node. A gateway is a Collector run as a central service that many agents send to. Applications know only the address of the agent, the agent knows only the address of the gateway, and the gateway holds the settings and credentials that exist once per environment. A Service with `internalTrafficPolicy: Local` keeps traffic on the node of the client.

An agent usually runs three processors, in a fixed order. `memory_limiter` comes first so that it can refuse data at the entrance when memory is high, and its hard limit must stay below the memory limit of the container. `resourcedetection` adds attributes about the source, such as the environment variable `OTEL_RESOURCE_ATTRIBUTES` through the `env` detector and the host name through the `system` detector. `batch` comes last and groups data into fewer requests. The Collector reads its configuration only at start, so a change needs a restart.

An agent has the authority that its pod specification gives it. Host mounts, host networking, privileged mode and API permissions each add reach, and receivers such as `filelog` explain why an agent may need some of them. An agent that only receives OTLP needs none. Its receiver port accepts data from any client that can reach it, and the Collector does not check the identity of the sender. Limit the access with network rules, transport security and checks at the gateway.

A local agent is a shared dependency with limits. Its queues are in memory and bounded, so data can be lost when the next tier is down or the agent restarts. Attribution needs care on a shared node: the application owns the service identity and the agent adds the facts about the host.

Key facts:

- Agent and gateway are roles of the same Collector program, defined by placement.
- Processor order is execution order, and `memory_limiter` goes first.
- An agent should have no more host access than its receivers need.
- A sender can claim any `service.name`, so identity needs controls outside the Collector.

<!-- astrona:playground:destroy -->
