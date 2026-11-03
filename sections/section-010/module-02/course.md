---
draft: true
exam_objectives:
  - Data Model
---
# Attributes, Metric Points And Exemplars

This module explains the details inside the telemetry items. It covers attribute types and limits, units, timestamps, the kinds of metric data point, aggregation temporality, exemplars and semantic conventions. You read each of them in the output of an OpenTelemetry Collector and then change the metric settings of a running service.

## Learning Goals

- Name the attribute value types and explain why high-cardinality attributes are a problem for metrics.
- Read units and timestamps correctly, including the start time of a data point.
- Tell a sum, a gauge and a histogram apart, and explain monotonicity and aggregation temporality.
- Explain what an exemplar is, which setting controls it, and how it links a metric point to a trace.
- Explain what a semantic convention and a schema URL are for.
- Configure delta temporality and exemplars on a service and prove the effect in the Collector output.

## Before You Start

You should know what a Deployment, an environment variable and a pod log are, and what a resource, a scope, a span and a trace ID are. The hands-on steps use a playground with a kind cluster, an OpenTelemetry Collector and a Python service built on the OpenTelemetry SDK. Technical terms are defined where they first appear.

## Reading Order

1. Attributes, Units And Timestamps
2. Metric Data Points And Temporality
3. Exemplars And Semantic Conventions
4. Summary

<!-- astrona:playground -->
