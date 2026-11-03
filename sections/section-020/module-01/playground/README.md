# API And SDK Separation — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
Starfleet example application in the `starfleet` namespace: the `shuttle`
Deployment (a Python service that uses the OpenTelemetry SDK, started from the
ConfigMap `shuttle-app`) and the `collector` Deployment (an OpenTelemetry
Collector with the `debug` exporter). Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path. The `shuttle` pod installs its packages with `pip` at start, so
allow a few minutes.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespace, Collector configuration, Collector, the `shuttle-app` ConfigMap and the `shuttle` Deployment |
| `docs/overview.md` | What the environment contains and ideas to try |
