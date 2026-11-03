---
draft: true
exam_objectives:
- Signals (Tracing, Metric, Log)
---
# Metrics With The OpenTelemetry SDK

This module explains how an application records metrics with the OpenTelemetry API and SDK: which instrument to pick, how the SDK aggregates measurements, how temporality and views change the exported data, and how the metric reader, cardinality and exemplars decide what leaves the process.

## Learning Goals

- Explain the roles of the `MeterProvider` and the `Meter`, and the split between the API and the SDK.
- Choose between a counter, an up-down counter, a histogram, a gauge and the asynchronous (observable) instruments.
- Name the default aggregation of each instrument and read a histogram data point.
- Explain cumulative and delta temporality and set the preference with an environment variable.
- Write a view that selects an instrument, drops attributes, changes bucket boundaries or drops the metric.
- Explain the periodic metric reader, the export interval and the flush on shutdown.
- Explain cardinality and why an unbounded attribute is a defect.
- Explain what an exemplar is and what the exemplar filter decides.

## Before You Start

You should know what a Deployment, a ConfigMap and an environment variable are, and you should be able to read pod logs with `kubectl`. The hands-on part uses a playground with a kind cluster. Technical terms are defined where they first appear.

## Reading Order

1. Meters And Instruments
2. Aggregation, Temporality And Views
3. Readers, Export Interval, Cardinality And Exemplars
4. Summary

<!-- astrona:playground -->
