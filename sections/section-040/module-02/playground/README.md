# Metrics With The OpenTelemetry SDK - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
`starfleet` namespace. The `shuttle` Deployment runs a Python program that uses
the OpenTelemetry SDK (`opentelemetry-sdk==1.45.2`) to record a counter, an
up-down counter, a histogram, a gauge, an observable gauge and an observable
counter. It sends them with OTLP/HTTP to the `collector` Deployment, which
prints them to its log. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-040-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path. The shuttle pod installs the SDK with pip on start, so wait about
two minutes before the first metrics appear in the Collector log.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/metrics-app.yaml` | Namespace, Collector, `shuttle-app` and `shuttle-views` ConfigMaps, `shuttle` Deployment |
| `docs/overview.md` | What the environment contains and ideas to try |
