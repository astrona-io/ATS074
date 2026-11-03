# Summary

The trace pipeline starts at the tracer provider, which holds the resource, the sampler and the span processors. The sampler decides for each new span whether it is dropped, recorded only, or recorded and sampled. The default sampler honours the decision of the parent, and a ratio sampler decides from the trace identifier so that all services reach the same answer for one trace. Spans that are not sampled never reach a processor that exports.

The span processor sits between the span and the exporter. The simple processor exports each span at once and blocks the caller during the export. The batching processor copies finished spans into a bounded queue and a worker thread exports them in batches. Four settings shape it: the schedule delay, the queue size, the batch size and the export timeout. When the queue is full the processor drops spans and logs a warning, so a slow or unreachable destination costs data instead of application latency.

The exporter turns spans into the OTLP wire format and sends them. With OTLP over HTTP the SDK appends the signal path to the configured endpoint, and a wrong port or protocol shows up as exporter errors in the application log while the application keeps running.

Flush and shutdown end the life of the pipeline. A flush exports what is queued and leaves the provider running. A shutdown flushes, stops the worker and releases the exporter. A pod receives `SIGTERM` first and `SIGKILL` after the grace period, so a handler that calls shutdown, together with a grace period longer than the drain time, decides whether the last spans arrive. An exit that skips the handlers, or a hard kill, loses whatever was still in the queue.

<!-- astrona:playground:destroy -->
