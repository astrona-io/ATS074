---
estimated_duration: 25m
---

# Lab: Tune The Python Instrumentation Agent

Graded lab for the language instrumentation agents module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `scout` app has no OpenTelemetry code. `opentelemetry-instrument` instruments it. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-01/labs/lab-01
astrona destroy ats-074-lab-070-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-flask-instrumentation-enabled.sh` | `flask` is not in `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` and the Collector log has fresh `GET /relay` or `GET /dock` server spans |
| `validate-service-identity.sh` | The Deployment sets the service name and namespace and fresh telemetry carries them (no `unknown_service`) |
| `validate-health-checks-excluded.sh` | `OTEL_PYTHON_EXCLUDED_URLS` names `healthz` and the last 40 seconds of the log have fresh spans but none for `/healthz` |
| `validate-workloads-running.sh` | Deployments are available, `scout` keeps its image and `start.sh`, and `app.py` still has no OpenTelemetry code |

The telemetry checks poll the Collector log for up to about 150 seconds.
