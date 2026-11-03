# Overview: Tracing With The OpenTelemetry Python SDK (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a Python application that creates spans and a Collector that prints them. There is no task, no `astrona submit` and no pass or fail. Change the environment variables or the application code, read the spans again, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- In the `starfleet` namespace:

  | Object | What it is |
  | --- | --- |
  | Deployment `shuttle` | A Python 3.12 application. It installs `opentelemetry-sdk` and `opentelemetry-exporter-otlp-proto-http` (version 1.45.2) with `pip` when the pod starts, then creates one trace every five seconds |
  | ConfigMap `shuttle-app` | Holds `app.py`, mounted at `/app`. Each trace has a `dock` span (kind `SERVER`) with the children `scan` and `report` |
  | Deployment `collector`, Service `collector` | The OpenTelemetry Collector (contrib distribution) with an OTLP receiver on ports 4317 (gRPC) and 4318 (HTTP) and the `debug` exporter at `detailed` verbosity |
  | ConfigMap `collector-config` | The Collector configuration |

- The `shuttle` is configured only with environment variables: `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_TRACES_SAMPLER` and `OTEL_BSP_SCHEDULE_DELAY`.
- Every third trace fails: the `report` span raises an exception.

## Read the spans

The first start is slow because of `pip install`. Follow the application until it prints `trace 1 finished`, then read the Collector:

```sh
kubectl -n starfleet logs deploy/shuttle --tail=5
kubectl -n starfleet logs deploy/collector --since=60s
```

## Practice tasks

- Find one `dock` trace in the Collector log. Write down its trace ID, then list the span IDs and the parent ID of `scan` and `report`.
- Find the `Links:` section of a `dock` span. Which span does the link point at, and is it in the same trace?
- Find a failed trace. Which spans have status code `Error`, and which span has an `exception` event?
- Run `kubectl -n starfleet set env deploy/shuttle OTEL_TRACES_SAMPLER=traceidratio OTEL_TRACES_SAMPLER_ARG=0.5` and wait for the new pod. Count how many of the next ten traces arrive.
- Run `kubectl -n starfleet set env deploy/shuttle OTEL_SERVICE_NAME-` and read the `service.name` resource attribute in the next batch.
- Edit `app.py` in `kubectl -n starfleet edit configmap shuttle-app`, add `scan.set_attribute("scan.sector", "alpha")`, restart the Deployment with `kubectl -n starfleet rollout restart deploy/shuttle` and find the new attribute.
