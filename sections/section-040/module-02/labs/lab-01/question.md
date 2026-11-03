# Question

Solve this question on: `terminal`

The `shuttle` program in the `starfleet` namespace exports metrics to the `collector` Deployment, which prints them in its log. The platform team has two problems. The program exports only once every 60 seconds, and the cumulative counters make short spikes hard to see. The histogram `shuttle.request.duration` also records a unique `request.id` on every measurement, so it creates a new time series for every request.

1. Configure `deploy/shuttle` with the standard OpenTelemetry environment variables so that it exports every 10 seconds and uses delta temporality for the instruments that support it. Do not edit the program code for this step.

2. In the ConfigMap `shuttle-views`, define a `View` in `VIEWS` that selects the instrument `shuttle.request.duration`, keeps only the attributes `http.route` and `http.response.status_code`, and aggregates with explicit buckets at 0.01, 0.05, 0.1, 0.25, 0.5 and 1.0 seconds. The program reads this file when it starts, so restart the Deployment.

3. Wait until the Collector log shows the result: `shuttle.requests` and `shuttle.request.duration` use delta temporality, `shuttle.queue.depth` is still cumulative, and the histogram data points have no `request.id` attribute.

`kubectl` already points at the cluster as the cluster administrator. A new shuttle pod needs about two minutes to install the SDK before it exports.
