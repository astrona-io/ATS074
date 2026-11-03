# Tracing With The OpenTelemetry Python SDK - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with two
Deployments in the `starfleet` namespace: `collector` (the OpenTelemetry
Collector with the `debug` exporter) and `shuttle` (a Python application that
creates spans with the OpenTelemetry SDK). Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path. The `shuttle` pod installs the SDK with `pip` on start: wait up
to five minutes for the first spans.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespace, Collector Deployment, ConfigMap and Service, `shuttle` Deployment and its `app.py` ConfigMap |
| `docs/overview.md` | What the environment contains and ideas to try |
