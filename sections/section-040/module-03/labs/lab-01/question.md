# Question

Solve this question on: `terminal`

The `shuttle` service in the `starfleet` namespace uses the OpenTelemetry Python SDK. It sends its log records to the `collector` Deployment, which prints them with the `debug` exporter (`kubectl -n starfleet logs deploy/collector`). A review of the records found four problems in the logs pipeline. Fix all four by changing the environment of the `shuttle` Deployment. Do not change the program in the ConfigMap `shuttle-app`, and do not delete, scale down or replace any Deployment.

1. Identity. The records have no service name. Set the service name to `shuttle`. Also add the resource attribute `deployment.environment.name` with the value `training`. Fresh log records must carry both values.

2. Volume. The `shuttle` writes DEBUG records that nobody reads. It must log at INFO or above, and no DEBUG record may reach the Collector.

3. Sensitive data. A troubleshooting switch left on puts a request header and an e-mail address into the attributes of the records. No record may carry `request.authorization` or `customer.email`.

4. Correlation. The ERROR records have an empty `Trace ID`, so they cannot be joined to the failed dispatch span. Every ERROR record must carry a trace ID.

The new pod installs the SDK when it starts and needs one or two minutes before the Collector shows its records. `kubectl` already points at the cluster. The names of the application settings are in the environment of the Deployment.
