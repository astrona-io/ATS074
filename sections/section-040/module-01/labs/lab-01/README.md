---
estimated_duration: 30m
---

# Lab: Fix Trace Identity, Sampling And Error Recording

Graded lab for the tracing module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

A Python application creates spans with the OpenTelemetry SDK and sends them to a Collector. It has no service name, its sampler drops every trace and its failing span records no error. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-074-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `collector` and `shuttle` have an available replica and their original images |
| `validate-service-name.sh` | `OTEL_SERVICE_NAME=shuttle` is set and the Collector log has `service.name: Str(shuttle)` |
| `validate-environment-attribute.sh` | `OTEL_RESOURCE_ATTRIBUTES` has `deployment.environment.name=lab` and `service.version=1.0.0`, and the Collector log shows the attribute |
| `validate-sampler-keeps-traces.sh` | The sampler is not `always_off` or a ratio below 1, and spans named `dock`, `scan` and `report` are in the Collector log |
| `validate-parent-child-recorded.sh` | A `scan` span has a non-empty parent ID |
| `validate-failure-recorded.sh` | A `report` span has status `Error` and an `exception` event |

The scripts read the Deployment environment and the last two minutes of `kubectl -n starfleet logs deploy/collector`, and poll for up to about two minutes. `validate-workloads-running.sh` passes before any change. The Collector `debug` exporter text format (`Parent ID`, `Name`, `Status code`, `-> Name: exception`) was checked against the Collector source, not against a running Collector.
