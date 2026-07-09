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
    echo "[OTel] Auto-instrumentation enabled"

    # Detect by checking the distro module directly. The `opentelemetry-instrument`
    # binary is also installed by `opentelemetry-instrumentation` (without distro),
    # so `command -v opentelemetry-instrument` would falsely report the auto-init
    # is wired up and skip the install — the SDK never initialises and traces stay
    # on the ProxyTracerProvider. Checking `opentelemetry.distro` is the precise
    # signal: the distro module is what actually configures the SDK on startup.
    if ! /app/.venv/bin/python -c "import opentelemetry.distro" &> /dev/null; then
        echo "[OTel] Installing opentelemetry-distro..."
        uv pip install --python /app/.venv/bin/python \
            opentelemetry-distro \
            opentelemetry-exporter-otlp \
            opentelemetry-instrumentation-system-metrics
        uv run opentelemetry-bootstrap -a requirements 2>/dev/null | while read -r pkg; do
            uv pip install --python /app/.venv/bin/python "$pkg" 2>/dev/null || true
        done
    fi

    echo "[OTel] Starting with auto-instrumentation: $@"
    exec opentelemetry-instrument "$@"
else
    echo "[OTel] Auto-instrumentation disabled, starting normally: $@"
    exec "$@"
fi
