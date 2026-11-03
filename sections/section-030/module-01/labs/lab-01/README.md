---
estimated_duration: 25m
---

# Lab: Fix The Identity And Environment Variables Of The shuttle Service

Graded lab for the SDK initialization, environment variable and resource module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. Open risks: the exact text of the Collector `debug` exporter lines that the checks match (`service.name: Str(shuttle)`), the pip install time, and how long a new pod takes to export.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-074-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-sdk-enabled.sh` | The `shuttle` rollout completes and `OTEL_SDK_DISABLED` is not `true` |
| `validate-service-name.sh` | Within about two minutes the Collector log shows `service.name: Str(shuttle)` in a fresh batch |
| `validate-resource-attributes.sh` | A fresh Collector log shows the requested `service.namespace`, `service.version` and `deployment.environment.name` |

The checks wait for fresh telemetry, so they pass only when the running pod has the new configuration. Every check fails before any change.
