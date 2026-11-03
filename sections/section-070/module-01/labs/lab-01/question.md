# Question

Solve this question on: `terminal`

The `scout` Deployment in `starfleet` is a Flask application with no OpenTelemetry code. It starts with `opentelemetry-instrument` and sends OTLP to the `collector` Service. The Collector prints every span, metric and log record, so you can read the result with `kubectl -n starfleet logs deploy/collector`. The telemetry has three problems. Fix them by changing the environment of the `scout` Deployment only.

1. The Flask instrumentation is switched off, so the Collector shows no server spans such as `GET /relay` or `GET /dock`. Make server spans reach the Collector again. Keep the instrumentation of the `requests` library on.

2. The telemetry has no service name, so the Collector shows `unknown_service`. Set the service name to `scout` and add the resource attribute `service.namespace=starfleet`.

3. The readiness and startup probes call `/healthz` every five seconds and fill the log with spans. Make the agent skip every request whose URL contains `healthz`.

Rules:

- Do not edit the ConfigMap `scout-app`. `app.py` must stay free of OpenTelemetry code and `start.sh` must still run `opentelemetry-instrument`.
- Do not delete, scale down or replace a Deployment, and keep the image of `scout`.
- The checks read the Deployment environment and the last minute of the Collector log, so wait for the new `scout` pod to become ready before you submit.

`kubectl` already points at the cluster. A new `scout` pod needs about two minutes to install its packages.
