# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output. Every restart of the `shuttle` pod takes a minute or more, and `astrona submit` waits and checks again for up to about two minutes.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `library-unchanged`. It stays your guard while you fix the pipeline.

## Step 1: Read the current configuration

List the environment of the container and the start-up line of the application:

```sh
kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value'
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
```

Four values need work. The endpoint uses port 4317, which is the gRPC receiver of the Collector, while `OTEL_EXPORTER_OTLP_PROTOCOL` is `http/protobuf`. `SHUTTLE_SPAN_PROCESSORS` is `simple`. `OTEL_TRACES_SAMPLER` is `always_off`. The start-up line shows the simple processor and a sampler that drops everything.

## Step 2: Repair the export path

Point the endpoint at the HTTP receiver and wait for the new pod:

```sh
kubectl -n starfleet set env deploy/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

The sampler still drops spans, but metrics and log records do not depend on the sampler. The metric `shuttle.jumps` now reaches the Collector. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-02/labs/lab-01 --keep
```

The check `export-path` passes.

## Step 3: Fix the processors and the sampler

Set the processor list, the batch delay and a parent-based sampler in one change, so the pod restarts only once:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_SPAN_PROCESSORS=crew-tag,batch OTEL_BSP_SCHEDULE_DELAY=2000 OTEL_TRACES_SAMPLER=parentbased_always_on
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
kubectl -n starfleet logs deploy/shuttle | grep "pipeline:"
```

The line now shows `processors=crew-tag,batch` and a sampler description that starts with `ParentBased{`. Grade it: the checks `processors` and `sampler` pass.

## Step 4: Confirm the custom attribute

The custom processor adds the attribute when a span starts, so spans of the new pod carry it:

```sh
kubectl -n starfleet logs deploy/collector --since=60s | grep -m 3 "starfleet.crew.size"
```

You see `starfleet.crew.size: Int(4)`. The check `custom-attribute` passes.

## Step 5: Record the evidence

Save this as `pipeline-evidence.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pipeline-evidence
  namespace: starfleet
data:
  processors: "crew-tag,batch"
  exporter-port: "4318"
  crew-size: "4"
```

Apply it:

```sh
kubectl apply -f pipeline-evidence.yaml
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS074.git -c sections/section-020/module-02/labs/lab-01
```

All six checks pass. Clean up with `astrona destroy ats-074-lab-020-02`.
