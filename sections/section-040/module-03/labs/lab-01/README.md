---
estimated_duration: 25m
---

# Lab: Repair A Logs Pipeline

Graded lab for the logs module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service sends logs, traces and metrics to an OpenTelemetry Collector, and its logs pipeline has four problems: no service name, DEBUG records, a sensitive payload in the records and error records without a trace ID. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-03/labs/lab-01
astrona destroy ats-074-lab-040-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

Every check except the first one polls for up to about 150 seconds for fresh records in the Collector log, because a new `shuttle` pod needs time to install the SDK.

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `collector` and `shuttle` have an available replica, their original images and the original code (the log bridge is still in the ConfigMap) |
| `validate-resource-identity.sh` | `OTEL_SERVICE_NAME` is `shuttle`, `OTEL_RESOURCE_ATTRIBUTES` has `deployment.environment.name=training`, and fresh records carry both values and no `unknown_service` |
| `validate-log-level.sh` | `SHUTTLE_LOG_LEVEL` is INFO or higher and no record in the last 20 seconds has `SeverityText: DEBUG` |
| `validate-no-sensitive-data.sh` | `SHUTTLE_LOG_PAYLOAD` is not `true` and no recent record has `request.authorization`, `customer.email` or `Bearer ` |
| `validate-trace-correlation.sh` | `SHUTTLE_LOG_INSIDE_SPAN` is not `false`, and every ERROR record in the last 30 seconds has a 32-character trace ID (at least one ERROR record exists) |

`validate-workloads-running.sh` passes before any change. It fails if a learner deletes or scales down a workload, or replaces the program, while fixing the settings.
