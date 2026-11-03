---
estimated_duration: 30m
---

# Lab: Route Telemetry Through A Collector Agent

Graded lab for the Collector agent and gateway module. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The `shuttle` SDK app sends OTLP straight to the gateway Collector. The agent Collector exists but has only a batch processor. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/module-02/labs/lab-01
astrona destroy ats-074-lab-070-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-shuttle-uses-agent.sh` | `OTEL_EXPORTER_OTLP_ENDPOINT` on `shuttle` names the `agent` Service |
| `validate-agent-processors.sh` | `agent-config` defines `memory_limiter`, `resourcedetection` with `env` and `system`, and `batch`; both pipelines list `memory_limiter` first and `batch` last |
| `validate-agent-enriches-telemetry.sh` | The gateway log has fresh `shuttle` spans with `host.name` and `deployment.environment.name: starfleet-lab` (proves the agent restarted with the new config) |
| `validate-workloads-running.sh` | Gateway, agent DaemonSet and `shuttle` are available, the agent still exports to `gateway:4317` and `gateway-config` has no resource processor |

The telemetry check polls the gateway log for up to about 150 seconds.
