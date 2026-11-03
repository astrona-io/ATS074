---
estimated_duration: 30m
---

# Lab: Tune Metric Export, Temporality And Views

Graded lab for the metrics module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. Open risks: the exact text that the Collector `debug` exporter prints, the time the shuttle pod needs to install the SDK, and how fast fresh metrics reach the log after a restart.

The cluster starts with a Collector and a `shuttle` program that exports every 60 seconds with cumulative temporality. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-074-lab-040-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-export-settings.sh` | `deploy/shuttle` has `OTEL_METRIC_EXPORT_INTERVAL` between 1000 and 10000 and a delta temporality preference, and its rollout is complete |
| `validate-views-configured.sh` | `views.py` in `shuttle-views` defines a `View` for `shuttle.request.duration` with `attribute_keys` and an explicit bucket aggregation, and does not keep `request.id` |
| `validate-delta-metrics-live.sh` | The Collector log of the last 45 seconds shows `shuttle.requests` and `shuttle.request.duration` as `Delta` and `shuttle.queue.depth` as `Cumulative` |
| `validate-histogram-view-live.sh` | The live histogram data points have no `request.id` and carry the boundary `0.050000` |

The live checks wait up to 120 seconds for fresh metrics. Every check fails before any change.
