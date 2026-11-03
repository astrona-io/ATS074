---
estimated_duration: 25m
---

# Lab: Fix A Trace Pipeline

Graded lab for the trace pipeline module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service uses the OpenTelemetry Python SDK with a trace pipeline that exports no spans: the `always_off` sampler, a simple span processor, no flush on `SIGTERM` and a one second grace period. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-074-lab-050-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `collector` and `shuttle` are available, the image is `python:3.12-slim` and the `shuttle-app` script is unchanged |
| `validate-sampler.sh` | The running pod has `OTEL_TRACES_SAMPLER=parentbased_traceidratio`, `OTEL_TRACES_SAMPLER_ARG=0.5` and the start log line agrees |
| `validate-batch-processor.sh` | `SHUTTLE_SPAN_PROCESSOR=batch`, queue at least 4096, batch size 1 to 256, schedule delay 100 to 2000 ms |
| `validate-shutdown-path.sh` | `SHUTTLE_ON_TERM=shutdown` and `terminationGracePeriodSeconds` of at least 30 |
| `validate-spans-exported.sh` | The Collector log has `shuttle.dock`, `shuttle.launch` or `shuttle.scan` spans of the current pod from the last 45 seconds (waits up to 150 s) |

The checks read the running pod, not only the Deployment, so they fail until the new pod is ready. `validate-workloads-running.sh` passes before any change only after the first pod start has finished.
