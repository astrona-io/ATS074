---
draft: true
exam_objectives:
  - Agents
---
# Summary

A language instrumentation agent adds telemetry to an application without a code change. For Python, `opentelemetry-distro` provides the SDK and the commands, `opentelemetry-bootstrap` installs an instrumentation package for each installed library, and `opentelemetry-instrument` starts the program with a `sitecustomize` module. That module builds the SDK and patches the libraries at runtime. All of this happens inside the application process, and only the export step leaves it.

The agent is configured with `OTEL_*` environment variables that it reads once at start. They set the exporters, the endpoint, the protocol, the service name and the resource attributes. The Python-specific variables disable chosen instrumentations or exclude URLs by regular expression. A command-line flag overrides the environment, and a change to the environment needs a new process.

The agent records what the instrumentors of supported libraries can see. A library without a matching instrumentation package, a version outside the supported range, a disabled instrumentation or a code path that bypasses the patched function produces no span and no error. Business meaning inside the application code is not visible. Manual instrumentation with the OpenTelemetry API fills that gap and works together with the agent, as long as the code does not create a second provider.

Key facts:

- The agent creates telemetry. The Collector only receives, changes and forwards it.
- Bootstrap sees only packages that are already installed.
- Coverage depends on the library, its version and the instrumentation setting.
- A missing span has a cause in the agent settings or the coverage, not in the Collector.

<!-- astrona:playground:destroy -->
