# Overview: Metrics With The OpenTelemetry SDK (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Change the settings, read the Collector log, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- The namespace `starfleet` with two Deployments:

  | Object | What it is |
  | --- | --- |
  | `deploy/shuttle` | A Python program that records metrics with the OpenTelemetry SDK 1.45.2 in a loop and exports them with OTLP over HTTP |
  | `deploy/collector` | The OpenTelemetry Collector (contrib 0.164.0). Its `debug` exporter prints every metric and span it receives, in detail |

- Two ConfigMaps for the program: `shuttle-app` holds `app.py` and `shuttle-views` holds `views.py`, a list named `VIEWS` that starts empty.
- The shuttle pod installs the SDK with pip when it starts. The first metrics reach the Collector after about two minutes. Pod names change after every restart.
- The program records these instruments: `shuttle.requests` (counter), `shuttle.queue.depth` (up-down counter), `shuttle.request.duration` (histogram, seconds), `shuttle.fuel.level` (gauge), `shuttle.engine.temperature` (observable gauge) and `shuttle.cpu.time` (observable counter). The first export interval is 10 seconds.
- The settings are the `OTEL_*` environment variables on `deploy/shuttle`. Change them with `kubectl -n starfleet set env deploy/shuttle NAME=value`.

## Helper

Paste this once in each new terminal. `metric_block` prints the part of the Collector log that describes one metric, from the last 60 seconds.

```sh
metric_block() {
  kubectl -n starfleet logs deploy/collector --since=60s \
    | awk -v name="$1" '/^Metric #/ {show=0} $0 ~ "-> Name: " name " *$" {show=1} show {print}'
}
```

Use it like this: `metric_block shuttle.request.duration | head -40`.

## Practice tasks

- Print each of the six metrics with `metric_block` and write down its `DataType`, `IsMonotonic` and `AggregationTemporality` lines. Explain why the gauges have no `AggregationTemporality`.
- Set `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` to `delta` and then to `lowmemory`. For each value, list which metrics change from `Cumulative` to `Delta`.
- Set `OTEL_METRIC_EXPORT_INTERVAL` to `2000` and then to `30000`. Count the exports in two minutes and compare the counter values.
- Count how many different `request.id` values the histogram prints. Explain what this does to the number of time series.
- Put a `View` in `shuttle-views` that keeps only `http.route` on `shuttle.request.duration`. Restart the Deployment and look at the attributes again.
- Add a second `View` with `aggregation=DropAggregation()` for `shuttle.cpu.time` and confirm that the metric disappears.
- Set `OTEL_METRICS_EXEMPLAR_FILTER` to `always_off`, then `always_on`, then `trace_based`, and read the `Exemplars` lines of the histogram each time.
