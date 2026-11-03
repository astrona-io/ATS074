---
estimated_duration: 45m
---

# Capstone Lab: Configure The shuttle SDK End To End

Capstone for the configuration section. It combines the environment variable rules, the resource, the exporter endpoint and headers, the sampler and the batch intervals. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. Open risks: the exact text of the Collector `debug` exporter lines, the pip install time and the wait time for fresh telemetry.

The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-074-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-resource-identity.sh` | Fresh Collector log shows `service.name: Str(shuttle)` and the requested namespace, environment and version |
| `validate-signals-delivered.sh` | Fresh `dock` spans and `shuttle.docks` metrics reach the Collector |
| `validate-sampler-and-batching.sh` | `parentbased_traceidratio`, argument `0.25`, `OTEL_BSP_SCHEDULE_DELAY` at most 2000 and `OTEL_METRIC_EXPORT_INTERVAL` at most 10000 |
| `validate-headers-from-secret.sh` | `OTEL_EXPORTER_OTLP_HEADERS` uses `secretKeyRef` to `collector-auth`/`otlp-headers`, the Secret holds the token and the Deployment text does not |

Every check fails before any change.
