# SDK Initialization, Environment Variables And Resources - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the namespace `starfleet`. The Deployment `shuttle` runs a small Python service that uses the real OpenTelemetry SDK (`opentelemetry-sdk==1.45.2`, installed with pip at pod start, so the pod needs about a minute). The Deployment `collector` runs the OpenTelemetry Collector contrib image with the `debug` exporter. The SDK is configured only through `OTEL_*` environment variables on the `shuttle` Deployment.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespace, the `shuttle` app script, the `collector` configuration and both Deployments |
| `docs/overview.md` | What the environment contains and ideas to try |
