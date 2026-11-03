---
estimated_duration: 25m
---

# Lab: Restore Telemetry From A Silent Service

Graded lab for the API and SDK separation module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service runs, but the Collector receives nothing from it. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-074-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-sdk-enabled.sh` | `OTEL_SDK_DISABLED` is not `true` and the running pod prints `tracer=Tracer` |
| `validate-service-name.sh` | Recent Collector output has the resource attribute `service.name: Str(shuttle)` |
| `validate-library-unchanged.sh` | The ConfigMap `shuttle-app` still holds `plot_course` and `configure_sdk`, and the image is `python:3.12-slim` |
| `validate-telemetry-arrives.sh` | Recent Collector output has the scope `starfleet.navigation`, the span `plot-course` and the metric `shuttle.jumps` |
| `validate-evidence-recorded.sh` | The ConfigMap `api-sdk-evidence` has the tracer class, the scope name, the SDK version from the Collector log and the service name |

The checks poll for up to about two minutes because the pod installs its packages when it starts. `validate-library-unchanged.sh` passes before any change.
