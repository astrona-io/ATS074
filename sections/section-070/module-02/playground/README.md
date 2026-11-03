# Collector Agent And Gateway Roles — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-070-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with two Collectors and one SDK app. The `agent` DaemonSet receives OTLP from the `shuttle` app, runs `memory_limiter`, `resourcedetection` and `batch`, and exports to the `gateway` Deployment. The gateway prints everything with the `debug` exporter. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-070-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Gateway, agent DaemonSet with its Service, and the `shuttle` SDK app |
| `docs/overview.md` | What the environment contains and ideas to try |
