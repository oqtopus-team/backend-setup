# OpenTelemetry Conventions

Rules for manual instrumentation across the backend services
(oqtopus-engine, device-gateway, tranqu-server).

## Span names

- A span that wraps a whole function is named `<service>.<function name>`,
  matching the function name exactly, including its case and any leading
  underscore.
  - Examples: `device_gateway.CallJob`, `device_gateway._execute`,
    `tranqu_server.Transpile`, `combiner.OptimalCombine`.
- A span that covers a phase inside a function, with no function of its own,
  is named `<service>.<enclosing function>.<phase>`, with the phase in
  lowercase snake_case.
  - Examples: `estimator._preprocess.qasm_parse`,
    `mitigator.ro_error_mitigation.build_calibration`.
- `<service>` is the package name (e.g. `tranqu_server`) and is always kept,
  so a span is identifiable on its own in the trace view.
- Keep names low-cardinality: no IDs or dynamic values in span names.

## Attribute names

- Attribute names stay lowercase snake_case even when the span they sit on
  is named after a CamelCase function, following the OTel attribute
  conventions.
- Service-local attributes: `<service>.<noun>[.<field>]`.
  - Examples: `device_gateway.circuit.num_qubits`, `tranqu_server.stats.after.depth`.
- Operation outcome: `<service>.<operation>.status`.
  - Examples: `device_gateway.call_job.status`, `tranqu_server.transpile.status`.
- Cross-service job attributes use the shared `oqtopus.` namespace and are
  propagated via baggage from the engine's per-job root span:
  `oqtopus.job_id`, `oqtopus.job_type`, `oqtopus.device_id`, `oqtopus.status`.

## Setting attributes

- Wrap attribute assignments in `if span.is_recording():` so that nothing is
  computed for telemetry when tracing is off. Values such as
  `qc.depth()` are otherwise evaluated on every request even with
  monitoring disabled.
- Attributes already known when the span starts are passed to
  `start_as_current_span` instead, so that a sampler can see them.
- `set_status` is not guarded: it is a no-op on a non-recording span and its
  argument carries no computation.

## Status values

- Use the job-domain vocabulary from the OQTOPUS job status:
  `succeeded` / `failed` (plus operation-specific states such as
  `device_inactive`).
- Also call `span.set_status(StatusCode.ERROR, ...)` on failure paths so
  trace backends mark the span as errored. Pass the exception message as is
  when there is an exception; when a failure carries no exception, describe
  what failed.

## Tracer names

- Give the tracer the same name as the logger of the same module, so the two
  never diverge.
- Imported modules keep `trace.get_tracer(__name__)`, matching
  `logging.getLogger(__name__)`.
- Modules launched directly (`python src/.../service.py`) pass the package
  name as a string, e.g. `trace.get_tracer("device_gateway")`. There
  `__name__` is `"__main__"`, which would name the instrumentation scope
  `__main__`; their loggers already use a literal for the same reason.

## Consuming span names in Grafana

- Do not use span names as filter conditions in dashboards or alert rules.
  Aggregate with `sum by(service_name, span_name)` and use attributes for
  filtering (`{ .oqtopus.job_id = "..." }`) instead.
- Span names still change: the move to the NEDO semantic conventions will
  rename them again. Keeping them out of query conditions keeps every such
  rename free.

## Timing

- Use `time.perf_counter()` for elapsed-time measurements, matching
  oqtopus-engine core.

## Enablement

- Application-level observability is gated by `monitoring.enabled` in each
  service's `config.yaml` (defaulting from the `MONITORING_ENABLED`
  environment variable via `oqtopus_util.config.load_config`).
- The SDK/exporter setup itself is owned by `opentelemetry-instrument` in
  `otel-entrypoint.sh`, gated by `OTEL_AUTO_INSTRUMENTATION_ENABLED`;
  standard `OTEL_*` variables stay environment-based per the OTel spec.
