---
estimated_duration: 40m
---

# Lab: Data Model Capstone

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. The task is in `question.md`; the walkthrough is in `solution.md`.

The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts. The validation scripts poll the Collector log for up to two minutes, because fresh telemetry appears only after the rollout and the next export.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-074-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-service-identity.sh` | The resource identifies the service and has no `request.id` |
| `validate-metrics-configured.sh` | Delta temporality and an exemplar filter that allows exemplars |
| `validate-collector-all-signals.sh` | The Collector log shows the resource, a delta sum, exemplars and a log record with a trace ID |
| `validate-data-model-record.sh` | The `data-model-record` ConfigMap states identity, temporality and unit |
| `validate-workloads-running.sh` | The Collector and the shuttle are available with their original images |
