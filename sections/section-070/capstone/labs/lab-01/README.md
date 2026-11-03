---
estimated_duration: 40m
---

# Capstone Lab: Agents End To End

Graded capstone for the agents section. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

It combines both modules: a zero-code Python app (`scout`) that must send through a Collector agent (DaemonSet) to a gateway Collector, with the right agent configuration, the right authority for the agent and the telemetry checked at the gateway. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-070/capstone/labs/lab-01
astrona destroy ats-074-capstone-070
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-agent-configured.sh` | `scout` exports to the `agent` Service, does not disable `flask`, sets `OTEL_SERVICE_NAME=scout` and excludes `healthz` |
| `validate-agent-processors.sh` | `agent-config` defines and orders `memory_limiter`, `resourcedetection` (`env`, `system`) and `batch` in both pipelines |
| `validate-agent-least-authority.sh` | The agent pod template has no `hostPath` volume, no privileged container and no `hostNetwork` |
| `validate-gateway-receives-enriched-telemetry.sh` | The gateway log has fresh `scout` server spans with `host.name` and the environment attribute, and no `/healthz` span |
| `validate-workloads-running.sh` | Workloads are available, `scout` stays zero-code, `gateway-config` has no `resourcedetection` or `memory_limiter` |

The telemetry check polls the gateway log for up to about 150 seconds.
