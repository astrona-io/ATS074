---
draft: true
exam_objectives:
  - Agents
---
# Agents

This section covers the two things OpenTelemetry calls an agent. The first is a language instrumentation agent, which runs inside an application process and adds telemetry without a code change. The second is the OpenTelemetry Collector in the agent role, which runs next to the applications, on a node or in a pod, and receives, processes and forwards their telemetry.

The section has two modules. The first uses the Python agent `opentelemetry-instrument` on a Flask application. The second runs a Collector as an agent (DaemonSet) in front of a Collector as a gateway. Each module has a playground for free exploration and a graded lab. A capstone lab combines both, and a quiz closes the section.

## Learning Outcomes

- Distinguish a language instrumentation agent from a Collector agent and say which of them creates telemetry.
- Install and start the Python agent with `opentelemetry-distro`, `opentelemetry-bootstrap` and `opentelemetry-instrument`.
- Set the service name, resource attributes, exporters, disabled instrumentations and excluded URLs with `OTEL_*` environment variables.
- Name what automatic instrumentation cannot record and decide when manual instrumentation is needed.
- Describe the agent and gateway roles, and compare sidecar and DaemonSet placement.
- Configure and order the `memory_limiter`, `resourcedetection` and `batch` processors in an agent.
- Identify the host access an agent needs, and the data and authority risks of a shared host.
