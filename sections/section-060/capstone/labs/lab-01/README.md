  ---
  estimated_duration: 40m
  ---

  # Lab: Context Propagation Capstone: Repair A Two-Service Trace

  Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. The scripts poll for fresh log lines for up to about 150 seconds because the pods install the SDK at start.

  The task is in `question.md`; the walkthrough is in `solution.md`.

  ## Run it

  ```sh
  astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/capstone/labs/lab-01
  astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/capstone/labs/lab-01
  astrona destroy ats-074-capstone-060
  ```

  ## Checks

  | Script | What it proves |
  | --- | --- |
  | `validate-workloads-running.sh` | collector, probe and shuttle are still available with their original images |
  | `validate-propagators-configured.sh` | shuttle and probe both set OTEL_PROPAGATORS=tracecontext,baggage |
  | `validate-trace-continued.sh` | probe.scan spans have a remote parent from the shuttle |
  | `validate-context-attached.sh` | Worker thread spans in the shuttle join the dispatch trace |
  | `validate-secret-removed.sh` | The session-token baggage entry is removed and mission still reaches the probe |
  | `validate-baggage-attribute-allowlist.sh` | Only the mission baggage key is copied to a span attribute |
  | `validate-propagation-report.sh` | propagation-report names a trace seen in shuttle, probe and collector logs |
