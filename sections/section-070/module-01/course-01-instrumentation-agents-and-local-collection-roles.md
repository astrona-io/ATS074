---
draft: true
exam_objectives:
- Agents
---
# Instrumentation Agents And Local Collection Roles

The word agent can describe two different roles in OpenTelemetry systems. An instrumentation agent or automatic instrumentation mechanism attaches supported hooks to an application's runtime and libraries. A Collector agent is a collection service placed near workloads, such as on a host or alongside an application. The first produces observations from code; the second receives or gathers telemetry and forwards it through configured processing.

Language instrumentation support depends on the actual ecosystem. Some runtimes use attachable agents, while others initialize instrumentation through packages or wrappers. Supported frameworks and library versions determine coverage. A mechanism that records HTTP calls may not understand an application-specific business decision. The application can still need manual instrumentation for that meaning.

A Collector agent can receive telemetry through a local endpoint or collect host-oriented information through supported receivers. It can apply resource enrichment, batching and other configured processing before export. This gives operators a managed place for delivery configuration without requiring every application to implement every backend integration. The Collector still needs the signal to be produced or collected; proximity alone does not invent missing spans.

Consider several services on a host. Each service can send OTLP data to an approved local collection endpoint. A host metrics receiver can also observe selected host measurements. The agent groups those inputs into configured pipelines and exports them onward. Application resource identity must remain distinct from host identity, otherwise several services may become indistinguishable in analysis.

Local collection can reduce the number of remote destinations each application needs to know. It can also centralize credentials used to reach the next collection tier. That simplification creates a shared operational dependency. If the agent becomes unavailable or overloaded, nearby workloads may lose or delay telemetry according to their SDK buffering behavior. A local endpoint is not an unlimited durable queue.

Placement affects authority. A host-level collector may need to read log files or host metadata. In a container environment, mounts and service identities determine what it can observe. Broad filesystem access can expose data unrelated to the intended workload. The agent should receive only the access required by its selected receivers and should not publish confidential content indiscriminately.

Sidecar and host-level placement have different tradeoffs. A sidecar can align lifecycle and configuration with one workload but increases per-workload resource use. A host agent can share collection capacity across workloads but needs careful tenant and resource attribution. The appropriate design depends on collection needs, isolation and operational ownership rather than a universal best placement.

The instrumentation and collection agents can fail independently. If an unsupported client library produces no spans, changing the Collector's batch size will not create them. If spans are produced but the local receiver is unreachable, rewriting the business span names will not repair delivery. Useful diagnosis follows the observation through production, local transport and processing.

Updates also need compatibility review. Instrumentation package changes can affect semantic conventions and supported hooks. Collector changes can affect available components and configuration fields. Keeping these lifecycles explicit makes it possible to identify whether a regression changed recording, identity or transport. One broad label such as agent error hides too much information.

## Common pitfalls

> [!WARNING]
> A Collector agent does not automatically instrument arbitrary application code. Review local collection privileges, resource attribution and capacity. Nearby placement simplifies some paths but still creates a managed dependency with failure and data-exposure boundaries.
