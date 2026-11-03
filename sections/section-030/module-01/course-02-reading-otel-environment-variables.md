---
draft: true
exam_objectives:
- Configuration
---
# Reading OTEL Environment Variables

The OpenTelemetry specification defines a set of environment variables that every SDK reads in the same way. They let an operator change the behavior of an application without a code change or a rebuild. This part explains which variables exist, how the SDK parses their values, and what it does when a value is wrong.

## Why environment variables

A container image is built once and run in many places. The service name, the Collector address and the sampling rate differ between a test cluster and production. Kubernetes sets environment variables per Deployment, so the same image gets a different configuration in each place.

The variables share one naming scheme. The prefix `OTEL_` marks a standard variable. After it comes the component, for example `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_TRACES_SAMPLER` or `OTEL_BSP_SCHEDULE_DELAY` (BSP stands for batch span processor). A variable that is specific to one signal adds the signal name, for example `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`.

The specification names a variable and its meaning. Each language SDK decides which of them it supports, and the SDK documentation lists the exceptions. A variable that the selected SDK does not support is not an error: the SDK never looks at it. The Python SDK in the playground reads `OTEL_RESOURCE_ATTRIBUTES`, `OTEL_SERVICE_NAME`, `OTEL_TRACES_SAMPLER`, `OTEL_BSP_*`, `OTEL_METRIC_EXPORT_INTERVAL` and the OTLP exporter variables, which are all the variables this section uses.

## The four value types

The specification defines how the SDK reads each type of value. The rules are strict on purpose, so that the same value means the same in every language.

A boolean is true only for the text `true`, in any letter case, so `True` and `TRUE` also count. Every other value is false. That includes `1`, `yes`, `on` and the empty text. The SDK should log a warning for a value that is not `true`, `false` or empty. The rule has a consequence that surprises many people: `OTEL_SDK_DISABLED=yes` does not disable the SDK.

A number must parse as a number. If it does not, the SDK should log a warning and treat the variable as unset, so the default applies. Time values are whole numbers of milliseconds, for example `OTEL_METRIC_EXPORT_INTERVAL=5000` means five seconds. Writing `5s` is not a number, so the SDK falls back to its default of 60000 milliseconds.

An enumerated value is one name from a fixed list, for example the sampler names. Names are case-insensitive. A name that is not on the list produces a warning and the SDK ignores the variable, which means the default applies.

A list is a comma-separated text. `OTEL_RESOURCE_ATTRIBUTES` and `OTEL_EXPORTER_OTLP_HEADERS` hold `key=value` pairs separated by commas. A semicolon is not a separator. The SDK splits at commas only, so a semicolon becomes part of a value.

An empty value counts as unset for every type. Setting `OTEL_TRACES_SAMPLER=""` therefore does not disable sampling. It selects the default.

## Default values and where they apply

When a variable is unset or ignored, the SDK uses the default of the specification. The defaults that matter most are:

| Variable | Default |
| --- | --- |
| `OTEL_SDK_DISABLED` | `false` |
| `OTEL_TRACES_SAMPLER` | `parentbased_always_on` |
| `OTEL_BSP_SCHEDULE_DELAY` | 5000 milliseconds |
| `OTEL_BSP_MAX_QUEUE_SIZE` | 2048 spans |
| `OTEL_METRIC_EXPORT_INTERVAL` | 60000 milliseconds |

A silent default is the main danger. A typo in a number turns a five-second export interval into sixty seconds, and nothing in the Collector looks wrong except that metrics arrive late.

## One flag disables everything

`OTEL_SDK_DISABLED=true` selects a no-op SDK for all signals. The application still runs and still calls the API, but nothing is recorded or exported. It exists for tests and emergency shut-off. It does not change propagators: context propagation keeps working so that a disabled service does not break the traces of the services around it.

## Trying the parsing rules

The playground service reads its settings at start, so a change in the Deployment restarts the pod. Change the metric interval to a value with a unit and watch the effect.

<!-- astrona:playground:renew -->

First set an invalid number:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_METRIC_EXPORT_INTERVAL=5s
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

Read the service log from the start and look for the warning that the SDK logs about the value. The exact warning text depends on the SDK version, so search for the variable name:

```sh
kubectl -n starfleet logs deploy/shuttle | grep -i -E 'OTEL_METRIC_EXPORT_INTERVAL|invalid' | head
```

Now count the metric exports that the Collector receives in one minute. With the interval of 5000 milliseconds the playground started with, you would see about twelve. With the ignored value the default of 60 seconds applies, so you see about one:

```sh
sleep 60; kubectl -n starfleet logs deploy/collector --since=60s | grep -c 'Name: shuttle.docks'
```

Restore the valid value and try a boolean that looks true but is not:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_METRIC_EXPORT_INTERVAL=5000 OTEL_SDK_DISABLED=yes
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
kubectl -n starfleet logs deploy/collector --since=30s | grep -Ec 'Name +: dock'
```

The count is greater than zero because `yes` is not `true`, so the SDK stays enabled. Set the value to `true` and repeat the last two commands. The new pod records no spans, so the span lines in the Collector log stop after the old pod stops. Remove the variable with `kubectl -n starfleet set env deploy/shuttle OTEL_SDK_DISABLED-` to continue.

## Environment against code

Code that passes an argument to a constructor usually wins over the environment. `BatchSpanProcessor(exporter, schedule_delay_millis=100)` ignores `OTEL_BSP_SCHEDULE_DELAY`. The environment variable is the fallback for a setting the code leaves open. This is why the `shuttle` code passes no arguments: the Deployment owns the settings.

This part showed that the SDK reads variables by fixed rules and falls back to a default without failing. The next part uses the same rules to build the identity of the service.

## Common pitfalls

> [!WARNING]
> Only `true` is true: `1`, `yes` and `on` are false. A number with a unit such as `5s` is ignored and the default applies. A semicolon does not separate list entries. An invalid value gives a warning in the application log, not an error, so check the log before you blame the Collector.
