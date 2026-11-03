---
estimated_duration: 25m
---

# Lab: Fix The Resource Of A Service

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. The task is in `question.md`; the walkthrough is in `solution.md`.

The `shuttle` pod installs the OpenTelemetry SDK with `pip` when it starts. The validation scripts poll the Collector log for up to two minutes, because fresh telemetry appears only after the rollout and the next export.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-074-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-service-name.sh` | The effective service name is `shuttle` |
| `validate-resource-attributes.sh` | `service.namespace`, `service.version` and `deployment.environment.name` are set |
| `validate-no-request-id.sh` | `request.id` is not a resource attribute |
| `validate-collector-resource.sh` | The Collector log of the last 30 seconds shows the corrected resource and no `request.id` |
| `validate-workloads-running.sh` | The Collector and the shuttle are available with their original images |
