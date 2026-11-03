---
estimated_duration: 25m
---

# Lab: Delta Temporality And Exemplars

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. The task is in `question.md`; the walkthrough is in `solution.md`.

The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts. The validation scripts poll the Collector log for up to two minutes, because fresh telemetry appears only after the rollout and the next export.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-074-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-temporality-configured.sh` | `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` is `delta` |
| `validate-exemplar-filter.sh` | `OTEL_METRICS_EXEMPLAR_FILTER` is `trace_based` or `always_on` |
| `validate-collector-delta.sh` | `shuttle.requests` arrives with `AggregationTemporality: Delta` |
| `validate-collector-exemplars.sh` | `shuttle.request.duration` data points carry exemplars |
| `validate-workloads-running.sh` | The Collector and the shuttle are available with their original images |
