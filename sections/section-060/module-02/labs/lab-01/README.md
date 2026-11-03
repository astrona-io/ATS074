  ---
  estimated_duration: 25m
  ---

  # Lab: Fix Propagators And Remove A Secret From Baggage

  Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it. The scripts poll for fresh log lines for up to about 150 seconds because the pods install the SDK at start.

  The task is in `question.md`; the walkthrough is in `solution.md`.

  ## Run it

  ```sh
  astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-02/labs/lab-01
  astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-060/module-02/labs/lab-01
  astrona destroy ats-074-lab-060-02
  ```

  ## Checks

  | Script | What it proves |
  | --- | --- |
  | `validate-workloads-running.sh` | collector, probe and shuttle are still available with their original images |
  | `validate-trace-continued.sh` | probe.scan spans have a remote parent from the shuttle |
  | `validate-secret-removed.sh` | The session-token baggage entry is removed and mission still reaches the probe |
  | `validate-propagation-policy.sh` | propagation-policy matches the propagators and baggage keys in use |
