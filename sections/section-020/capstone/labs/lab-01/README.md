---
estimated_duration: 45m
---

# Capstone: Composability And Extension

Capstone lab for the composability and extension section. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service has six faults at once: the SDK is never registered, the service has no name, the exporter port is wrong, the span processor and sampler are wrong, and propagation is off. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-074-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-sdk-registered.sh` | `SHUTTLE_CONFIGURE_SDK` is not `false`, `OTEL_SDK_DISABLED` is not `true` and the pod prints `tracer=Tracer` |
| `validate-resource.sh` | Recent Collector output has `service.name: Str(shuttle)` and `deployment.environment.name: Str(staging)` |
| `validate-export-path.sh` | The endpoint ends in port 4318 and recent Collector output has the metric `shuttle.jumps` |
| `validate-processors-and-sampler.sh` | The pod prints `processors=crew-tag,batch` and `TraceIdRatioBased{0.5}`, and the Collector shows `starfleet.crew.size: Int(4)` |
| `validate-propagation.sh` | The pod log shows `injected headers: ['traceparent']` |
| `validate-library-unchanged.sh` | The ConfigMap `shuttle-app` still holds `plot_course` and `configure_sdk`, and the image is `python:3.12-slim` |
| `validate-evidence-recorded.sh` | The ConfigMap `composability-evidence` matches the pod log and the Collector log |

The checks poll for up to about two minutes because the pod installs its packages when it starts. With the ratio 0.5 only about half of the traces are exported, so span checks may need a few more seconds. `validate-library-unchanged.sh` passes before any change.
