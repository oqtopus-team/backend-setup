# OpenTelemetry Conventions

Rules for manual instrumentation across the backend services
(oqtopus-engine, device-gateway, tranqu-server).

## Span names

- Format: `<service>.<operation>[.<phase>]`, lowercase snake_case.
  - Examples: `tranqu_server.transpile`, `device_gateway.call_job`,
    `device_gateway.execute.qasm_parse`, `estimator.preprocess.operator`.
- `<service>` is the package name (e.g. `tranqu_server`), which may differ
  from the gRPC method name (`Transpile` follows protobuf/gRPC casing;
  the auto-instrumented RPC span already carries that name).
- Keep names low-cardinality: no IDs or dynamic values in span names.

## Attribute names

- Service-local attributes: `<service>.<noun>[.<field>]`.
  - Examples: `device_gateway.circuit.num_qubits`, `tranqu_server.stats.after.depth`.
- Operation outcome: `<service>.<operation>.status`.
  - Examples: `device_gateway.call_job.status`, `tranqu_server.transpile.status`.
- Cross-service job attributes use the shared `oqtopus.` namespace and are
  propagated via baggage from the engine's per-job root span:
  `oqtopus.job_id`, `oqtopus.job_type`, `oqtopus.device_id`, `oqtopus.status`.

## Status values

- Use the job-domain vocabulary from the OQTOPUS job status:
  `succeeded` / `failed` (plus operation-specific states such as
  `device_inactive`).
- Also call `span.set_status(StatusCode.ERROR, ...)` on failure paths so
  trace backends mark the span as errored.

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
