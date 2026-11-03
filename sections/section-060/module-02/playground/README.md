# Propagators, Baggage And Broken Propagation - Playground

- **Slug:** ats-074-playground-060-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with an OpenTelemetry Collector, a `shuttle` service that calls a `probe` service over HTTP, and the OpenTelemetry Python SDK in both. The pods install the SDK with `pip` at start, so the first start takes a few minutes.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-060-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/01-seed-cluster.sh` | Applies the manifest and waits for the rollouts |
| `manifests/starfleet.yaml` | Namespace, collector, probe and shuttle (application code is in the two `*-app` ConfigMaps) |
| `docs/overview.md` | What the environment contains and ideas to try |
