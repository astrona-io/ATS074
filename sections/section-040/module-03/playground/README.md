# Logs: Records, The Logs SDK And Trace Correlation — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-040-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with two
Deployments in `starfleet`: `collector` (OpenTelemetry Collector contrib
0.164.0, OTLP receiver, `debug` exporter with detailed output) and `shuttle`
(Python 3.12 with `opentelemetry-sdk` 1.45.2, which exports traces, metrics and
logs to the collector). The `shuttle` installs the SDK with `pip` at start, so
allow a few minutes. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-040-03
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespace, ConfigMaps `shuttle-app` and `collector-config`, Deployments and Service |
| `docs/overview.md` | What the environment contains and ideas to try |
