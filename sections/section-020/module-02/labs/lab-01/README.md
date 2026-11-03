---
estimated_duration: 30m
---

# Lab: Repair A Misconfigured SDK Pipeline

Graded lab for the SDK components module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service has a wrong exporter port, the wrong span processor, a sampler that drops every trace and a custom processor that is not enabled. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-074-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-export-path.sh` | The endpoint ends in port 4318 and recent Collector output has the metric `shuttle.jumps` |
| `validate-processors.sh` | The running pod prints `processors=crew-tag,batch` and `OTEL_BSP_SCHEDULE_DELAY` is `2000` |
| `validate-sampler.sh` | The running pod prints a `ParentBased{` sampler and recent Collector output has the span `plot-course` |
| `validate-custom-attribute.sh` | Recent Collector output has `starfleet.crew.size: Int(4)` |
| `validate-library-unchanged.sh` | The ConfigMap `shuttle-app` still holds `plot_course` and `configure_sdk`, and the image is `python:3.12-slim` |
| `validate-evidence-recorded.sh` | The ConfigMap `pipeline-evidence` has the processor list, the port and the crew size seen at the Collector |

The checks poll for up to about two minutes because the pod installs its packages when it starts. `validate-library-unchanged.sh` passes before any change.
