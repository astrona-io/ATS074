---
draft: true
exam_objectives:
  - Signals (Tracing, Metric, Log)
---
# Logs: Records, The Logs SDK And Trace Correlation

Logs are the signal for individual events. A metric counts, a trace follows one request, and a log record says what a component reported at one moment. This module teaches the OpenTelemetry log data model, the SDK pipeline that moves records to a Collector, the bridge from the Python standard `logging` module, the fields that join a record to a trace, events, retention and sensitive data.

<!-- astrona:playground -->

The playground is a kind cluster with the `starfleet` namespace. The `shuttle` Deployment runs a Python program with the OpenTelemetry SDK. It sends traces, metrics and logs over OTLP/HTTP to the `collector` Deployment, which prints every record with the `debug` exporter. You read the records with `kubectl -n starfleet logs deploy/collector`.

## Learning Goals

- Name the fields of a log record and explain what each one is for.
- Map severity text to the severity number bands.
- Describe the path of a record: `LoggerProvider`, `Logger`, processor, exporter.
- Choose between the simple and the batch log record processor.
- Explain how the standard `logging` bridge builds a record.
- Explain when a record carries a trace ID and a span ID, and when it does not.
- Describe events and how they differ from messages.
- Account for volume, retention and sensitive data in a logs pipeline.

## Before You Start

You need `kubectl` and `jq`, and you should be able to read a Deployment and a ConfigMap. No knowledge of Python is needed beyond reading a few lines of code. Each part uses the playground. Pods are slow to start, because the `shuttle` installs the SDK with `pip` when it starts, so allow a minute or two after every change to the Deployment.

## Reading Order

The module has four parts and a summary. The first part reads the fields of a log record. The second part follows a record through the SDK to the Collector. The third part bridges the standard `logging` module and follows a trace ID from a record to a span. The fourth part covers events, volume, retention and sensitive data. A graded lab follows the fourth part: you fix the logs pipeline of the `shuttle` in a cluster.
