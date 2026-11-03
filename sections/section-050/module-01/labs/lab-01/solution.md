# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-01/labs/lab-01
```

The first start takes several minutes because the `shuttle` pod installs the SDK with `pip`.

## Step 1: Read the starting configuration

Print what the SDK was told at start:

```sh
kubectl -n starfleet logs deployment/shuttle | grep '\[shuttle\] config'
```

The line shows `sampler=always_off`, `span_processor=simple` and `on_term=exit`. The `always_off` sampler decides that no trace is recorded, so no span reaches a processor and the Collector has nothing to print. Confirm that the Collector has no spans:

```sh
kubectl -n starfleet logs deployment/collector --since=60s | grep -c 'shuttle\.dock'
```

The count is `0`.

## Step 2: Change the sampler

`parentbased_traceidratio` samples a root span with probability `0.5` and makes every child span follow its parent. Set both variables in one command so the pod restarts once:

```sh
kubectl -n starfleet set env deployment/shuttle OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.5
```

Grade it after the new pod is ready:

```sh
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-01/labs/lab-01 --keep
```

The check `sampler-ratio` passes.

## Step 3: Use the batching span processor

The batching span processor puts ended spans in a queue and a background thread exports them in batches. Set the queue, batch and delay variables together. The batch size must not be larger than the queue size, or the SDK raises an error at start:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_SPAN_PROCESSOR=batch OTEL_BSP_MAX_QUEUE_SIZE=4096 OTEL_BSP_MAX_EXPORT_BATCH_SIZE=256 OTEL_BSP_SCHEDULE_DELAY=2000
```

Wait for the new pod and grade it. The check `batch-processor` passes.

## Step 4: Flush and shut down on SIGTERM

`SHUTTLE_ON_TERM=shutdown` makes the script call `shutdown` on the tracer, meter and logger providers when it receives `SIGTERM`. That call flushes the span queue. It needs time, so raise the termination grace period of the pod to 30 seconds:

```sh
kubectl -n starfleet set env deployment/shuttle SHUTTLE_ON_TERM=shutdown
kubectl -n starfleet patch deployment shuttle --type=merge -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":30}}}}'
```

Wait for the new pod:

```sh
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
```

## Step 5: Confirm that spans arrive

Read the Collector log of the last minute and count the spans of the new pod:

```sh
kubectl -n starfleet logs deployment/collector --since=60s | grep -E 'Name +: shuttle\.(dock|launch|scan)$' | sort | uniq -c
```

You see counts for the three span names. About half of the root spans reach the Collector, because the ratio is `0.5`. Every `shuttle.refuel` child span appears only together with a sampled root span. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-050/module-01/labs/lab-01
```

All five checks pass. Clean up with `astrona destroy ats-074-lab-050-01`.
