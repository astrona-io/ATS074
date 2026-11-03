---
draft: true
exam_objectives:
  - Agents
---
# Collector Agent And Gateway Roles

This module explains how the OpenTelemetry Collector works as an agent next to applications and as a gateway for a whole cluster, how each role is deployed, which processors an agent needs, and which risks come from running a Collector close to workloads on a shared host. The hands-on work uses a playground with a gateway, an agent DaemonSet and an application that uses the OpenTelemetry SDK.

## Learning Goals

- Describe the agent role and the gateway role of the Collector, and when a deployment uses one or both.
- Compare sidecar and DaemonSet placement, and explain how an application reaches a node-local agent.
- Configure the `memory_limiter`, `resourcedetection` and `batch` processors and justify their order.
- Identify the authority an agent gets from host mounts and receivers, and the data risks of a shared host.

## Before You Start

You should know what a Collector pipeline is (receivers, processors and exporters), and what a DaemonSet, a Service and a ConfigMap are in Kubernetes. The hands-on part uses a playground with a kind cluster, `kubectl` and `jq`. Technical terms are defined where they first appear.

## Reading Order

1. Agent And Gateway Roles
2. Processors In The Agent
3. Authority And Shared-Host Data Risks
4. Summary

<!-- astrona:playground -->
