# Trace Pipeline - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-050-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
OpenTelemetry Collector (`collector`) and the `shuttle` service in the
`starfleet` namespace. The `shuttle` environment variables start a batching span processor with a 2 second schedule delay. Nothing to submit.

The `shuttle` pod runs `pip install` for the OpenTelemetry SDK at start, so
wait several minutes until `kubectl -n starfleet get pods` shows it ready.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-050-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespace, Collector, Service and the shuttle application (script in a ConfigMap) |
| `docs/overview.md` | What the environment contains and ideas to try |
