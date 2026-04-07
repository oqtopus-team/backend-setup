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

USE_UV=false
if command -v uv &> /dev/null; then
    USE_UV=true
fi

OTEL_ENABLED="${OTEL_AUTO_INSTRUMENTATION_ENABLED:-false}"

if [ "$OTEL_ENABLED" = "true" ]; then
    echo "[OTel] Auto-instrumentation enabled"

    if ! command -v opentelemetry-instrument &> /dev/null; then
        echo "[OTel] Installing opentelemetry-instrument..."
        if [ "$USE_UV" = "true" ]; then
            uv pip install \
                opentelemetry-distro \
                opentelemetry-exporter-otlp \
                opentelemetry-instrumentation-system-metrics
            uv run opentelemetry-bootstrap -a requirements 2>/dev/null | while read -r pkg; do
                uv pip install "$pkg" 2>/dev/null || true
            done
        else
            pip install --quiet --disable-pip-version-check \
                opentelemetry-distro \
                opentelemetry-exporter-otlp \
                opentelemetry-instrumentation-system-metrics
            opentelemetry-bootstrap -a install 2>/dev/null || true
        fi
    fi

    echo "[OTel] Starting with auto-instrumentation: $@"
    exec opentelemetry-instrument "$@"
else
    echo "[OTel] Auto-instrumentation disabled, starting normally: $@"
    exec "$@"
fi
