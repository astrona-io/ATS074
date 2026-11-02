---
draft: true
exam_objectives:
- Context Propagation
---
# Active Context, Injection, Extraction And Baggage

Context propagation connects related work across execution boundaries. A local context carries execution-scoped values, including active span information where appropriate. A propagator serializes selected values into a carrier for remote communication and extracts them on the receiving side. The carrier might be HTTP headers or supported message metadata. The mechanism establishes relationships; it does not transport the entire trace history.

Within a process, code must preserve the relevant context across function calls and asynchronous work. A language's runtime and instrumentation library provide mechanisms for associating context with execution. Creating a child span while the wrong context is active can attach it to an unrelated request. Creating it with no relevant parent can make it appear as a separate root.

Across a process boundary, injection and extraction have complementary roles. A client injects the selected context into the outgoing request. A server extracts that context before starting related work. Both sides need compatible propagator support and must preserve the carrier fields through intermediate infrastructure. A reverse proxy or message adapter that drops them can break the relationship while the business request still succeeds.

Trace context carries identifiers and related tracing metadata. It allows a downstream span to participate in the intended trace under the configured recording policy. Baggage carries selected contextual key-value data that applications choose to propagate. Baggage is not automatically equivalent to span attributes or metric dimensions; instrumentation must explicitly use it where that behavior is supported and intended.

Consider an order request that calls inventory and then queues background fulfillment. The HTTP call can carry context through headers. The queue message needs its own supported metadata path. The consumer may use parent relationships or links according to the message-processing semantics. Copying a trace identifier into a free-text body without a compatible extraction contract does not establish a functioning propagation mechanism.

Asynchronous operations make lifecycle reasoning important. Work can outlive the original server operation or be influenced by several messages. A simple parent-child tree may not fully represent every causal relationship. Links allow a span to associate with other span contexts where appropriate. They should express actual relationships rather than inventing a parent solely to make the displayed graph look complete.

Propagated input crosses a trust boundary. A caller can supply context fields, including identifiers or baggage values. These values should not be treated as proof of identity or permission. A trace identifier is useful for correlation, not an authentication credential. Baggage should not contain tokens, confidential payloads or unrestricted values that will spread into downstream services.

Limits and filtering matter because every propagation hop can enlarge exposure. A value added at an entry point can travel to dependencies outside the original team's control. If that value later becomes a metric attribute, it can also create high cardinality. The design should define allowed contextual information, destination boundaries and supported size behavior rather than forwarding every header indiscriminately.

Diagnosis follows the causal path. Identify the outgoing carrier, intermediary behavior, receiver extraction and local active-context handling. If the business request succeeds but traces split, transport reachability may be healthy while propagation is broken. If context exists but spans are absent, sampling or recording can be a separate cause. Those cases should not be repaired by treating every received identifier as trusted authority.

## Common pitfalls

> [!WARNING]
> Trace IDs and baggage are not authorization. Propagation requires compatible injection, carrier preservation and extraction, including asynchronous boundaries. Avoid forwarding sensitive values or assuming that baggage automatically becomes every signal's attributes.
