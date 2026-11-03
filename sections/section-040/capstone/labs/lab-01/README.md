---
estimated_duration: 40m
---

# Lab: Correlate Traces, Metrics And Logs

Capstone lab for the signals section. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service sends traces, metrics and logs to an OpenTelemetry Collector. All three signals have a problem, and one of the problems is shared: the Resource has no service name. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-074-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

Every check except the first one polls for up to about 150 seconds for fresh telemetry in the Collector log, because a new `shuttle` pod needs time to install the SDK.

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `collector` and `shuttle` have an available replica, their original images and the original code |
| `validate-resource-shared.sh` | Every Resource block of logs, spans and metrics in the last 30 seconds has `service.name: Str(shuttle)` and `deployment.environment.name: Str(training)`, and each signal appears at least once |
| `validate-traces-exported.sh` | A span named `dispatch` was received in the last 30 seconds |
| `validate-metrics-exported.sh` | `OTEL_METRIC_EXPORT_INTERVAL` is not above 15000 and the metric `shuttle.dispatch.count` was received in the last 40 seconds |
| `validate-logs-hygiene.sh` | Fresh log records arrive, none has `SeverityText: DEBUG`, none has `request.authorization`, `customer.email` or `Bearer ` |
| `validate-log-trace-correlation.sh` | Every ERROR record of the last 30 seconds has a 32-character trace ID and the same trace ID belongs to a span received in the last 60 seconds |
