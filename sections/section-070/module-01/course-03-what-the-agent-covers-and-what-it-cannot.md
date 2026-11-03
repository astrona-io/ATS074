---
draft: true
exam_objectives:
  - Agents
---
# What The Agent Covers And What It Cannot

Zero-code instrumentation is attractive because it needs no code change. It is not complete, and an operator who assumes it is will look for data that does not exist. This part describes the rule for what the agent records, shows a span that holds only technical facts, and explains when the application also needs manual instrumentation with the OpenTelemetry API.

## The coverage rule

The agent records what an instrumentor for a library can see. An instrumentor wraps the entry and exit points of one library. It sees the arguments and the result of those calls. It does not see the code of your application between those calls.

Three conditions must be true for a library call to produce a span. The instrumentation package for the library must exist and be installed. The installed version of the library must be inside the range that the package supports. The instrumentation must not be disabled. When one condition fails, the call runs normally and produces nothing. There is no error, which is why the gap is easy to miss.

## What the Flask span contains

Look at a server span for the `/dock` route. Print the span block that follows the line with the span name:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -A 30 -m 1 'Name *: GET /dock'
```

The block shows the trace identifier, the span identifier, the kind (`Server`), the start and end time and a list of attributes. The attributes describe the HTTP request: the method, the route, the status code, the server address and the user agent. The exact attribute names depend on the version of the instrumentation and on the semantic convention setting. A semantic convention is an agreed name and meaning for an attribute, so that every tool reads the same fact in the same way.

Search the last minute for the business facts of the handler:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -ci 'berth'
```

The count is `0`. The `/dock` handler picks a berth and a wait time, and these are the facts that the team cares about. The agent saw the request and the response status. It did not see the variable `berth` inside the function, because no library call carried it.

## Seeing a library drop out

Switch off one instrumentation and watch what changes. Disable the `requests` instrumentation:

```sh
kubectl -n starfleet set env deployment/scout OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=requests
kubectl -n starfleet rollout status deployment/scout --timeout=420s
```

After the new pod has sent a batch, count the client spans:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -cE 'Kind +: Client'
```

The count is `0`. The `/relay` handler still calls `/status` and the answer still arrives, but the outgoing call is no longer a span. The Flask instrumentation still records the inner `GET /status` server span. In the trace, that span now has no client parent from this process. The application worked in both cases. Only the observation changed.

Restore the earlier state by removing the variable:

```sh
kubectl -n starfleet set env deployment/scout OTEL_PYTHON_DISABLED_INSTRUMENTATIONS-
```

## What the agent cannot cover

Several things lie outside the reach of automatic instrumentation.

- **Unsupported libraries and versions.** A library with no instrumentation package, or a version outside the supported range, produces nothing.
- **Code between library calls.** Business decisions, loops and calculations are invisible. The agent cannot name a span after a business step.
- **Business attributes.** Order values, customer tiers or the berth in the example appear only if the code adds them.
- **Calls that bypass the patched function.** A program that talks to a service through a raw socket, or through a library the agent does not patch, makes no client span.
- **Process models that fork.** A server that starts worker processes after the agent has set up the SDK can lose export threads in the workers. Such servers need setup in each worker, which is a known need in the Python documentation.
- **Stable behavior over time.** Attribute names and span names follow the version of the instrumentation package and the semantic convention setting. An upgrade can rename an attribute that a dashboard uses.

## Adding manual instrumentation to an agent

Manual instrumentation means calling the OpenTelemetry API from the application code. It works together with the agent. The agent builds the SDK and registers the providers as global. Code that calls `trace.get_tracer(...)` and `start_as_current_span(...)` then receives the tracer of the agent SDK. The span nests under the Flask server span of the active request.

For the `/dock` handler, one span named `assign-berth` with the attribute `berth` would add the missing business fact. The code needs only the API package for that. The code must not create a new tracer provider or a new exporter, because the agent already did.

The decision between the two methods is practical. Use the agent for the common library layer: incoming requests, outgoing requests, database drivers. Add manual spans at the places where the business meaning lives. Teams that cannot change the code get the first layer and accept the missing second one.

## A checklist for a missing span

When a span you expect does not appear, work through the chain in order. Each question points at one component.

1. Does the application call the library at all? A request that never reaches the handler cannot produce a span.
2. Is the instrumentation package installed? Run `pip list` in the container and look for the name of the library.
3. Is the library version supported? The package declares the range of versions it can patch, and the agent skips the library outside it.
4. Is the instrumentation disabled or the URL excluded by a variable? Read the Deployment environment.
5. Does the `console` exporter print the span? If yes, the agent works and the next step is the transport.
6. Does the Collector receive it? The Collector log answers this.

The order moves from the application outward. A change at step six, such as a new batch size in the Collector, cannot repair a failure at step two.

## Checking the cost and the risk

An agent adds work to each call it wraps and memory for the SDK buffers. The cost is usually small for HTTP calls and can be large for libraries that make very many tiny calls. Measure it in a test environment. The agent is also another set of packages with its own versions. Pin them, and test the upgrade of the distro together with the application.

You now can say what the Python agent records and why it stops at library boundaries. Telemetry that the agent produces still has to travel to a backend, and that job belongs to the Collector.

## Common pitfalls

> [!WARNING]
> Missing data does not raise an error: an unsupported or disabled library simply produces no span. Do not try to fix missing spans in the Collector, because it cannot create what was never recorded. Do not assume that zero-code means zero effort: versions, forking servers and renamed attributes still need attention. Never create a second tracer provider next to the agent.
