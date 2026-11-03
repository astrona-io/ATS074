---
draft: true
exam_objectives:
  - Signals (Tracing, Metric, Log)
---
# Events, Retention And Sensitive Data

Log records are the cheapest signal to create and the easiest one to abuse. A developer adds a line to find a bug, the line stays in the code, and a year later the service writes millions of records a day, some of them with passwords in them. This part covers the three decisions that keep a logs pipeline useful: when to record an event instead of a message, how much to keep and for how long, and which data must never leave the process.

## Events

An event is a log record that has an event name. The name says what kind of occurrence the record describes, for example `shuttle.docked`. Records with the same event name are expected to have the same attributes, so a backend can treat them as one kind of thing. A plain log message has no such promise: its body is free text. An event is the right form for a business or lifecycle occurrence that you want to count, query and graph, such as a user login, a deployment step or a payment result.

In the Logs API an event is created with the same `emit` method, with the `event_name` argument set. The `shuttle` emits one event after each successful dispatch. The name is part of the record, and the debug exporter prints an `EventName` line only for records that have one. The line is missing for ordinary messages.

<!-- astrona:playground:renew -->

Find the events in the Collector log of the playground:

```sh
kubectl -n starfleet logs deploy/collector --since=45s | grep -A6 "EventName" | head -16
```

Each match shows the name, the body line and the attributes of the event. The event has no message in its body, because its meaning is in the name and in the attribute `shuttle.dispatch.number`. Keep event names stable and few: a name that contains an id or a timestamp is a message in disguise.

## Volume, severity and cost

Every record costs CPU time in the application, network bandwidth, Collector time and storage. Debug records are the biggest source. The `shuttle` creates one debug record for each dispatch, and a busy service creates thousands per second. There are four places to reduce volume, in the order in which they save the most:

1. The application level, such as `SHUTTLE_LOG_LEVEL`. A record below the level is never created.
2. The `enabled` check of the SDK, which a processor can use to skip creating records for a scope or severity.
3. A filter in the Collector, which drops records after they have crossed the network.
4. The backend, which can drop or move data to cheaper storage.

The earlier the filter, the cheaper the result. The logs SDK has no sampler: unlike traces, there is no built-in way to keep one record in ten. Keep records that describe errors, and keep records that belong to sampled traces. Records for a dropped trace are the first candidates to remove.

## Retention

The SDK does not store anything. It queues records for a few seconds and then sends them. Retention, the time that records stay available, belongs to the systems after the SDK. In the playground there are two such systems. The `debug` exporter writes to the standard output of the Collector, and the container runtime rotates that output: the kubelet keeps by default at most five files of 10 MiB each for a container. Older lines disappear. A backend such as a log database has its own retention setting, often counted in days.

For this reason, an empty search does not prove that an event did not happen. The record may have been dropped by a full queue, filtered by the Collector, never exported because the process was killed, or deleted by retention. Write down the retention of each system that holds logs, and match it to how long an investigation needs the data.

## Sensitive data

A log record can leave the process with anything that the code passed to it: a bearer token, an e-mail address, a card number, a full request body. Once the record is in the Collector and a backend, many more people and systems can read it than could read the original request. Three rules apply.

First, do not record what you do not need. Log the identifier of a customer, not the e-mail. Second, record at the source what is safe by default and require a deliberate change to log more. The `shuttle` has a troubleshooting switch, `SHUTTLE_LOG_PAYLOAD`, that is `false` in the playground. Third, remove values before the record is exported. A `LogRecordProcessor` sees the writable record, so it can replace a sensitive attribute with a fixed text. Register it before the batch processor, because the batch processor can export the record soon after it queues it. This is Python code to read, not a command to run:

```python
class RedactProcessor(LogRecordProcessor):
    SENSITIVE = {"request.authorization", "customer.email"}

    def on_emit(self, log_record):
        attributes = log_record.log_record.attributes
        for key in self.SENSITIVE:
            if key in attributes:
                attributes[key] = "[redacted]"

    def shutdown(self):
        pass

    def force_flush(self, timeout_millis=30000):
        return True
```

The Collector offers a second line of defence: its attributes processor can delete or hash an attribute, and the redaction processor can mask values that match a pattern. Use both layers. A rule in the Collector protects against services that you do not control, and a rule in the process keeps the value off the network completely.

## See the leak and close it

Turn the troubleshooting switch on. The pod restarts and installs the SDK again, so wait for the rollout:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_PAYLOAD=true
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
```

After about 20 seconds, look for the sensitive attributes in the Collector log:

```sh
kubectl -n starfleet logs deploy/collector --since=30s | grep -E "request.authorization|customer.email" | head -4
```

The lines show the values in clear text. The token in the example is made up, but the path is real: a record with a real token would be stored and searchable. Turn the switch off, and the new records no longer carry the attributes:

```sh
kubectl -n starfleet set env deploy/shuttle SHUTTLE_LOG_PAYLOAD=false
```

Records that were already exported stay in the Collector log until the log rotates. Turning a switch off does not remove old data. You now know the three levers of a logs pipeline: what a record means, how much of it you keep and what it must not contain.

## Common pitfalls

> [!WARNING]
> Do not treat the absence of a record as proof that something did not happen: queues, filters, kills and retention all remove records. Do not leave payload logging on after debugging, because secrets that were exported cannot be taken back. Do not put ids or timestamps into event names. A redaction processor registered after the batch processor can run too late, because the batch processor may already have queued and exported the record.
