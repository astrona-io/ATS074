  ---
  estimated_duration: 25m
  ---

  # Lab: Attach Context To A Worker Thread And Read A traceparent

  Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. The scripts poll for fresh log lines for up to about 150 seconds because the pods install the SDK at start.

  The task is in `question.md`; the walkthrough is in `solution.md`.

  ## Run it

  ```sh
  astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-01/labs/lab-01
  astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-01/labs/lab-01
  astrona destroy ats-074-lab-060-01
  ```

  ## Checks

  | Script | What it proves |
  | --- | --- |
  | `validate-workloads-running.sh` | collector, probe and shuttle are still available with their original images |
  | `validate-context-attached.sh` | Worker thread spans in the shuttle join the dispatch trace |
  | `validate-traceparent-evidence.sh` | traceparent-evidence matches a real header and the span that sent it |
  | `validate-collector-received-spans.sh` | The collector logs shuttle.dispatch and probe.scan spans |
