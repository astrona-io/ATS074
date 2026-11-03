---
estimated_duration: 25m
---

# Lab: Fix Metric And Log Pipelines

Graded lab for the metric and log pipeline module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service uses the OpenTelemetry Python SDK with a metric reader that exports every 120 seconds, no view, cumulative temporality and a log record queue of two records. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-02/labs/lab-01
astrona destroy ats-074-lab-050-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `collector` and `shuttle` are available, the image is `python:3.12-slim` and the `shuttle-app` script is unchanged |
| `validate-metric-reader.sh` | `OTEL_METRIC_EXPORT_INTERVAL` is 1000 to 10000 ms, the temporality is `delta` and the Collector log shows a delta metric from the current pod |
| `validate-views.sh` | `SHUTTLE_VIEWS` has `keys`, `buckets` and `drop-fuel`; the Collector log of the last 30 seconds has `shuttle.requests`, the bucket boundary 0.25, no `shuttle.client` and no `shuttle.fuel.used` |
| `validate-log-processor.sh` | `OTEL_BLRP_MAX_QUEUE_SIZE` at least 2048, batch size 1 to 512, and log records with a trace ID reach the Collector |

The checks read the running pod and wait up to about 2.5 minutes for fresh telemetry. The Collector output format (`Name:`, `ExplicitBounds`, `Trace ID:`) comes from the `debug` exporter at `detailed` verbosity and was not checked on a running cluster.
