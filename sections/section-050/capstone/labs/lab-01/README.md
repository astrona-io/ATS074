---
estimated_duration: 40m
---

# Capstone Lab: Repair The SDK Pipelines Of A Service

Graded capstone for the SDK pipelines section. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` service uses the OpenTelemetry Python SDK, and none of its three signal pipelines delivers data: the exporter points at the wrong port, the sampler is `always_off`, the batch queues hold two items, the metric reader exports every 120 seconds, and the process does not flush on `SIGTERM`. The learner repairs the trace, metric and log pipelines and records the configuration as evidence. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-074-capstone-050
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `collector` and `shuttle` are available, the image is `python:3.12-slim` and the `shuttle-app` script is unchanged |
| `validate-endpoint.sh` | The endpoint names the `collector` Service on port 4318 and the pod log of the last minute has no export failure |
| `validate-traces.sh` | `parentbased_traceidratio` with a ratio of 0.1 to 0.5, batching processor, queue at least 2048, batch at most 512, delay at most 5000 ms, spans at the Collector |
| `validate-metrics.sh` | Export interval 1000 to 10000 ms, delta temporality, views `keys` and `drop-fuel`, and their effect in the Collector log |
| `validate-logs.sh` | `OTEL_BLRP_MAX_QUEUE_SIZE` at least 2048, batch at most 512, log records with trace IDs at the Collector |
| `validate-shutdown-path.sh` | `SHUTTLE_ON_TERM=shutdown` and a grace period of at least 30 seconds |
| `validate-pipeline-evidence.sh` | The `pipeline-evidence` ConfigMap matches the environment of the running pod |

The checks read the running pod and wait up to about 2.5 minutes for fresh telemetry. The Collector output format comes from the `debug` exporter at `detailed` verbosity and was not checked on a running cluster.
