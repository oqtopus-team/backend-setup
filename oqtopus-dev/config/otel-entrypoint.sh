#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OpenTelemetry Auto-Instrumentation Entrypoint
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# When OTEL_AUTO_INSTRUMENTATION_ENABLED=false (default),
# the script simply passes through to the original command
# with zero overhead.

set -e

export PATH="$HOME/.local/bin:$PATH"

if [ -d "/app/.venv/bin" ]; then
    export PATH="/app/.venv/bin:$PATH"
fi

OTEL_ENABLED="${OTEL_AUTO_INSTRUMENTATION_ENABLED:-false}"

if [ "$OTEL_ENABLED" = "true" ]; then
    # The OTel packages (opentelemetry-distro, opentelemetry-exporter-otlp,
    # opentelemetry-instrumentation-system-metrics, plus any service-specific
    # instrumentations) are declared as runtime dependencies in each service's
    # pyproject.toml and installed at image-build time via `uv sync`. They are
    # therefore guaranteed to be present here and pinned consistently with the
    # rest of the locked dependency set.
    #
    # An earlier version of this script installed them at container start
    # (`uv pip install opentelemetry-distro opentelemetry-exporter-otlp ...`).
    # That pulled the latest pypi release independently of the project's
    # locked sdk version, and when the exporter ran ahead of the sdk it broke
    # LogProvider init with a silent ImportError of SDK-internal constants
    # (`OTEL_PYTHON_SDK_INTERNAL_METRICS_ENABLED`) — traces kept flowing but
    # log export silently dropped. The runtime install block has been removed
    # in favour of build-time install for predictable, reproducible images.
    echo "[OTel] Auto-instrumentation enabled, starting with: $@"
    exec opentelemetry-instrument "$@"
else
    echo "[OTel] Auto-instrumentation disabled, starting normally: $@"
    exec "$@"
fi
