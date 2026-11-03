---
estimated_duration: 30m
---

# Lab: Repair The Exporter, Sampler And Interval Settings

Graded lab for the exporter, sampler and declarative configuration module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. Open risks: the exact text of the Collector `debug` exporter lines (`Name : dock`, `Name: shuttle.docks`), the pip install time and the wait time for fresh telemetry.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-074-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-traces-delivered.sh` | Within about two minutes the Collector log shows a fresh `dock` span |
| `validate-metrics-delivered.sh` | The Collector log shows `shuttle.docks` and the interval is at most 10000 ms |
| `validate-sampler-configuration.sh` | The Deployment has `OTEL_TRACES_SAMPLER=parentbased_traceidratio`, `OTEL_TRACES_SAMPLER_ARG=0.5` and an endpoint on port 4318 |

Every check fails before any change.
