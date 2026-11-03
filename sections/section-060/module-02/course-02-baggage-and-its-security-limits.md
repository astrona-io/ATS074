---
draft: true
exam_objectives:
  - Context Propagation
---
# Baggage And Its Security Limits

Trace context answers one question: which trace does this work belong to. Sometimes a service also needs to pass a small piece of business data to every service downstream, for example the name of a mission or a customer tier. Baggage is the OpenTelemetry signal-independent way to do that. This part explains how baggage works, what it does not do, and the security limits that make it dangerous to misuse. The playground sends a harmless value and a fake credential, so you can see both.

## What baggage is

Baggage is a set of name-value pairs stored in the Context, next to the current span. Code adds a pair with `baggage.set_baggage(name, value, context)`, which returns a new Context, and reads pairs with `baggage.get_baggage(name, context)` or `baggage.get_all(context)`. The `baggage` propagator writes the pairs into the `baggage` HTTP header on injection and reads them on extraction, so the pairs travel to every service that continues the request.

The W3C Baggage header is a comma-separated list of members. Each member has the form `key=value`, and a member can add properties after a semicolon. Keys and values are percent-encoded when they contain special characters. For example, the playground header is `mission=survey,session-token=demo-not-a-real-secret`.

The W3C specification asks implementations to support at least 64 members, 8192 bytes in total and 4096 bytes in one member. An implementation may drop members that exceed the limits, so a long list can lose entries without an error. Keep baggage small.

## What baggage does not do

Baggage is not trace context, and it does not change what a span records. The pairs exist only in the Context. A pair does not become a span attribute, a metric attribute or a log attribute unless your code, or a component you configure, copies it there. There is no automatic copy in the API or in the SDK.

Baggage is also not an authorization mechanism. The `baggage` header is plain text and it is set by the caller. Any client that sends a request can add any pair, including the names your code trusts. A service must treat every received pair as untrusted input, in the same way as any other HTTP header.

## Observing baggage in the playground

The `shuttle` code that creates the pairs is short. It builds a new Context for each pair, because a Context is immutable, and then attaches the final one:

```python
ctx = context.get_current()
ctx = baggage.set_baggage("mission", "survey", ctx)
token = context.attach(ctx)
```


The `shuttle` sets two pairs, and the `probe` prints every pair it receives. Check what leaves the `shuttle` and what arrives:

<!-- astrona:playground:renew -->
```sh
kubectl -n starfleet logs deploy/shuttle --tail=4 | grep ' role=client '
```

The `baggage=` field of the client line holds the exact header value, with `mission=survey` and `session-token=demo-not-a-real-secret`. Then read the `probe`:

```sh
kubectl -n starfleet logs deploy/probe --tail=4 | grep '^PROPAGATION'
```

The `probe` line shows the same two pairs in its `baggage=` field, written as `mission=survey;session-token=...`. The `probe` did nothing to ask for them. The `baggage` propagator extracted them, and the application read them with `baggage.get_all`. The value is visible to any code in that process, in any log line that prints the header, and in any proxy or monitoring tool that records headers on the way.

## Baggage compared with other contextual data

The three kinds of data look alike, because each is a set of key-value pairs. They differ in where they live and how far they go.

| Data | Where it lives | How far it goes | Who decides |
| --- | --- | --- | --- |
| Span attribute | On one span | To the backend only | The code that sets it |
| Resource attribute | On the service, for all its telemetry | To the backend only | The deployment configuration |
| Baggage | In the Context | To every downstream service | The code that sets it, then every receiver |

Use a span attribute when only your own backend needs the value. Use baggage only when a downstream service needs the value to do its work, and the value is safe to share.

## The security limits

Baggage crosses every boundary that the request crosses. If the `probe` calls a third-party service over HTTP, and the HTTP client instrumentation injects the active context, the third party also receives `session-token`. The request leaves your trust boundary and the value goes with it. Nothing in the API removes it.

Four rules follow from this.

- Do not put secrets, credentials, personal data or authorization decisions in baggage. Use it only for values that are safe to show to every service and every proxy on the path.
- Do not trust a received pair. Validate it before use, and never use it as proof of identity or permission.
- Control the list at the edge. A service at the entry point of your system can remove or replace incoming baggage, so a client outside your system cannot inject pairs.
- Keep the number of pairs and their size small, because they increase the size of every request.

## Turning baggage into an attribute on purpose

A pair becomes an attribute only when code copies it. The `probe` has an allowlist in the environment variable `PROBE_BAGGAGE_ATTRIBUTES`. For each key in the list, the code reads the value from the extracted baggage and sets a span attribute named `baggage.<key>`. Keys that are not in the list are never copied. Allow one key and send a new `probe` pod:

```sh
kubectl -n starfleet set env deployment/probe PROBE_BAGGAGE_ATTRIBUTES=mission
kubectl -n starfleet rollout status deployment/probe --timeout=300s
```

Wait about a minute, and then search the collector output. The `debug` exporter prints every attribute of every span it receives:

```sh
kubectl -n starfleet logs deploy/collector | grep 'baggage\.'
```

You see `baggage.mission` on `probe.scan` spans and no `baggage.session-token`. Only the allowlisted key became an attribute. The credential still arrives in the baggage of every request and shows in the `probe` log line, so the allowlist protects the telemetry, not the request path. Removing the pair at the source is the only fix for the request path.

An allowlist has a second purpose: cardinality. If a pair holds a request ID or a user ID and code copies it onto a metric, every value creates a new time series. Copy only low-cardinality keys, and copy them to spans before you copy them to metrics.

You now know that baggage is data in the Context, that a propagator carries it across processes, that nothing makes it an attribute by itself, and that it reaches everyone downstream. The open question is how to find the place where propagation breaks when a trace or a baggage value does not arrive.

## Common pitfalls

> [!WARNING]
> Baggage is sent in clear text to every downstream service, including services you do not own, so a secret in baggage is a leak. It is not authorization, because any caller can set any pair. It is not a span attribute until code copies it, so a dashboard that expects a baggage key as an attribute stays empty. Receivers may drop pairs above the W3C size limits without an error.
