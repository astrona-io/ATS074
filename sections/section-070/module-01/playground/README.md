# Language Instrumentation Agents — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-074-playground-070-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with a Collector (`collector`) that prints all telemetry, a Flask app (`scout`) with no OpenTelemetry code that runs under `opentelemetry-instrument`, and a client (`drifter`) that calls it. Nothing to submit. The `scout` pod runs `pip install` on start, so it needs about two minutes.

## Run it

```sh
astrona run -c .
astrona destroy ats-074-playground-070-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Collector, `scout` with its ConfigMap (`start.sh`, `app.py`) and the `drifter` client |
| `docs/overview.md` | What the environment contains and ideas to try |
