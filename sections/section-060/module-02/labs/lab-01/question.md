# Question

Solve this question on: `terminal`

The `shuttle` Deployment in `starfleet` calls the `probe` Service. The `shuttle` sends a `traceparent` header, but traces still split at the `probe`. A security review also found a credential in the baggage that the `shuttle` sends to the `probe`.

1. Find out why the `probe` does not continue the trace of the `shuttle`, and fix it with the standard environment variable for propagators. The `probe.scan` span must have a remote parent in a trace that the `shuttle` started. The `probe` must still receive baggage.

2. Stop sending the credential in baggage. The `shuttle` takes its baggage entries from the environment variable `SHUTTLE_BAGGAGE`. Keep `mission=survey`. No recent `shuttle` or `probe` log line may contain `session-token`.

3. Record the policy in a ConfigMap `propagation-policy` in `starfleet` with these keys:
   - `propagators`: the value of `OTEL_PROPAGATORS` that both services now use.
   - `baggage-keys`: the baggage keys that the `shuttle` sends, separated by commas.

   Both Deployments must set `OTEL_PROPAGATORS` explicitly to that value.

4. Do not delete or scale down any workload.

The `shuttle` and the `probe` print `PROPAGATION` lines in their pod logs. `kubectl` already points at the cluster. The pods need a minute or two to start after a change.
