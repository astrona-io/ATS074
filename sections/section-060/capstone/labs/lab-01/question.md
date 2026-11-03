# Question

Solve this question on: `terminal`

The `shuttle` Deployment in `starfleet` calls the `probe` Service. The team opens a trace for one request and finds three problems: the `probe.scan` span is a separate trace, the `shuttle.audit` span from the worker thread is a separate trace, and the `probe` and collector logs show a credential that travels in baggage. Repair the propagation and prove it.

1. Both services must propagate trace context and baggage with the W3C formats. Set the standard environment variable on both Deployments to the exact value `tracecontext,baggage`.

2. The `probe.scan` span must have a remote parent in a trace that the `shuttle` started.

3. The `shuttle.audit` span must be a child of the `shuttle.dispatch` span in the same trace. Do not edit the application code. The `shuttle` reads `SHUTTLE_ATTACH_CONTEXT`.

4. The `shuttle` takes its baggage from `SHUTTLE_BAGGAGE`. Keep `mission=survey` and stop sending the credential.

5. The `probe` copies the baggage keys listed in its environment variable `PROBE_BAGGAGE_ATTRIBUTES` onto its span as attributes named `baggage.<key>`. Allow only `mission`. The collector must log `baggage.mission` on `probe.scan` spans and never a `baggage.session-token` attribute.

6. Record the result in a ConfigMap `propagation-report` in `starfleet` with these keys:
   - `trace-id`: the ID of one trace that appears in the `shuttle` log (a client line and a worker line with a parent), in the `probe` log (with `remote=true`) and in the collector log.
   - `propagators`: the value you set in step 1.
   - `baggage-keys`: the baggage keys now sent, separated by commas.

7. Do not delete or scale down any workload.

`kubectl` already points at the cluster. The pods need a minute or two to start after a change.
