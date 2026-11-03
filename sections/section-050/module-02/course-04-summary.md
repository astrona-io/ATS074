# Summary

The metric pipeline combines measurements inside the process. A meter provider hands each instrument call to the streams that match it, and an aggregation turns the calls into one data point for each set of attribute values. Counters sum, histograms count values into buckets, and a stream that drops is not stored at all. Views let the owner of the service rename streams, keep only some attributes, set histogram bounds or drop a stream without changing the instrumentation. The cardinality limit stops an unbounded attribute from using all memory, at the price of an overflow point.

A metric reader decides when data leaves the process. The periodic reader collects on a timer, controlled by the export interval and the export timeout, and passes the data to an exporter. A short interval gives fresh data at a higher cost, and a long one gives coarse data. Cumulative temporality reports totals since the start and survives a missed export. Delta temporality reports only the change and loses increments when an export fails. A provider shutdown or a flush collects once more, and a kill does not.

The log pipeline connects to the logging library of the application through a bridge. The bridge adds the trace identifier and the span identifier of the active span, so logs and traces can be joined. The batching log processor works with a bounded queue, a schedule delay, a batch size and an export timeout. When the queue is full it drops records and the application continues, so delivery is at most once.

For all three signals the same rules decide reliability: bounded buffers that drop under pressure, exporters that retry only within a timeout, and a shutdown path that must run to completion before the process is killed. A good configuration chooses limits for each of these on purpose.

<!-- astrona:playground:destroy -->
