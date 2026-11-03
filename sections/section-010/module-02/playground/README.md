# Attributes, Metric Points And Exemplars - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with an
OpenTelemetry Collector (`otel/opentelemetry-collector-contrib:0.164.0`) and the
`shuttle` service in the `starfleet` namespace. The service uses the
OpenTelemetry Python SDK 1.45.2 and exports traces, metrics and logs over
OTLP/HTTP. The Collector prints every item with the `debug` exporter. The pod
installs the SDK with `pip` at start, so the first start takes a few minutes.
Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Collector, its configuration, the `shuttle` application script and its Deployment |
| `docs/overview.md` | What the environment contains and ideas to try |
