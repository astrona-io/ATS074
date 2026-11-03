# Question

Solve this question on: `terminal`

The `shuttle` Deployment in `starfleet` sends a request to the `probe` Service every 5 seconds. A review of the traces found two problems. The `shuttle.audit` span, which the `shuttle` starts on a worker thread, always begins a new trace. The team also wants a record of the header that links the two services.

1. Make the `shuttle.audit` span a child of the `shuttle.dispatch` span, in the same trace. Do not edit the application code. The application reads the environment variable `SHUTTLE_ATTACH_CONTEXT`.

2. Record one real `traceparent` header in a ConfigMap `traceparent-evidence` in `starfleet` with these keys:
   - `version`: the version field of a `traceparent` value that the `probe` received.
   - `trace-id`: its trace ID.
   - `parent-id`: its parent ID. It must be the span ID of the `shuttle.dispatch` span that sent the request.
   - `trace-flags`: its trace flags.

3. Do not delete or scale down any workload.

The `shuttle` and the `probe` print `PROPAGATION` lines in their pod logs. `kubectl` already points at the cluster. The pods need a minute or two to start after a change.
