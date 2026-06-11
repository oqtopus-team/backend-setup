#!/bin/bash

set -euo pipefail

mode=${1:-run}
project_dir=${PROJECT_DIR:-$(pwd)}
env_file=${ENV_FILE:-$project_dir/config/.env}
baseline_file=${BASELINE_FILE:-$project_dir/config/.env.baseline}
log_file=${LOG_FILE:-$project_dir/logs/env-baseline-daily-check.log}
schedule=${CRON_SCHEDULE:-0 3 * * *}

load_env() {
  [ -f "$env_file" ] || return 0
  DEVICE_ID=${DEVICE_ID:-$(read_env_value DEVICE_ID)}
  SUBNET_PREFIX=${SUBNET_PREFIX:-$(read_env_value SUBNET_PREFIX)}
}

read_env_value() {
  local key=$1
  sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*//p" "$env_file" \
    | tail -1 \
    | sed 's/[[:space:]]#.*$//' \
    | sed 's/^"//; s/"$//; s/^'\''//; s/'\''$//'
}

hash_keys() {
  local source_file=$1
  [ -f "$source_file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
      *=*) ;;
      *) continue ;;
    esac
    local key=${line%%=*}
    local value=${line#*=}
    key=${key// /}
    [ -n "$key" ] || continue
    printf '%s\t%s\n' "$key" "$(printf '%s' "$value" | sha256sum | cut -d' ' -f1)"
  done < "$source_file" | sort
}

check_drift() {
  if [ ! -f "$baseline_file" ]; then
    mkdir -p "$(dirname "$baseline_file")"
    hash_keys "$env_file" > "$baseline_file"
    echo "DRIFT_COUNT=0"
    return 0
  fi

  local current_hashes baseline_hashes added removed changed
  current_hashes=$(hash_keys "$env_file")
  baseline_hashes=$(cat "$baseline_file")
  added=""; removed=""; changed=""

  while IFS=$'\t' read -r key hash_value; do
    [ -n "$key" ] || continue
    baseline_hash=$(printf '%s\n' "$baseline_hashes" | awk -F'\t' -v key="$key" '$1==key{print $2; exit}')
    if [ -z "$baseline_hash" ]; then
      added="$added${added:+,}$key"
    elif [ "$baseline_hash" != "$hash_value" ]; then
      changed="$changed${changed:+,}$key"
    fi
  done <<< "$current_hashes"

  current_keys=$(printf '%s\n' "$current_hashes" | cut -f1)
  while IFS=$'\t' read -r key hash_value; do
    [ -n "$key" ] || continue
    printf '%s\n' "$current_keys" | grep -qxF "$key" || removed="$removed${removed:+,}$key"
  done <<< "$baseline_hashes"

  drift_count=0
  for drift_group in "$added" "$removed" "$changed"; do
    [ -n "$drift_group" ] && drift_count=$((drift_count + $(printf '%s' "$drift_group" | tr ',' '\n' | grep -c .)))
  done
  echo "DRIFT_COUNT=$drift_count"
  [ -n "$added" ] && echo "ADDED=$added"
  [ -n "$removed" ] && echo "REMOVED=$removed"
  [ -n "$changed" ] && echo "CHANGED=$changed"
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

label_value() {
  printf '%s\n' "$drift_output" | sed -n "s/^$1=//p" | head -1 | tr -d '"\\' | tr '[:space:]' '_'
}

push_metric() {
  local drift_count=$1
  local endpoint=${OTLP_ENDPOINT:-}
  if [ -z "$endpoint" ]; then
    endpoint="http://${SUBNET_PREFIX:-172.20.0}.30:4318"
  fi
  case "$endpoint" in
    */v1/metrics) metrics_url=$endpoint ;;
    *) metrics_url=${endpoint%/}/v1/metrics ;;
  esac

  local time_unix_nano hostname_value instance_value added changed removed
  time_unix_nano=$(date +%s%N)
  hostname_value=$(hostname -s 2>/dev/null || hostname)
  instance_value=${DEVICE_ID:-$hostname_value}
  added=$(json_escape "$(label_value ADDED)")
  changed=$(json_escape "$(label_value CHANGED)")
  removed=$(json_escape "$(label_value REMOVED)")

  payload='{"resourceMetrics":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"oqtopus-env-baseline-check"}},{"key":"host.name","value":{"stringValue":"'"$(json_escape "$hostname_value")"'"}},{"key":"instance","value":{"stringValue":"'"$(json_escape "$instance_value")"'"}},{"key":"device_id","value":{"stringValue":"'"$(json_escape "$instance_value")"'"}}]},"scopeMetrics":[{"scope":{"name":"oqtopus.env-baseline-daily-check"},"metrics":[{"name":"env_drift_keys","gauge":{"dataPoints":[{"timeUnixNano":"'"$time_unix_nano"'","asDouble":'"$drift_count"',"attributes":[{"key":"source","value":{"stringValue":"backend"}},{"key":"added","value":{"stringValue":"'"$added"'"}},{"key":"changed","value":{"stringValue":"'"$changed"'"}},{"key":"removed","value":{"stringValue":"'"$removed"'"}}]}]}}]}]}]}'
  curl -fsS -X POST -H 'Content-Type: application/json' --data "$payload" "$metrics_url"
}

run_check() {
  [ -f "$env_file" ] || { echo "env file not found: $env_file" >&2; exit 1; }
  load_env
  drift_output=$(check_drift)
  printf '%s\n' "$drift_output"
  drift_count=$(printf '%s\n' "$drift_output" | sed -n 's/^DRIFT_COUNT=//p' | head -1)
  push_metric "${drift_count:-0}"
}

install_cron() {
  mkdir -p "$(dirname "$log_file")"
  script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
  command="cd $project_dir && PROJECT_DIR=$project_dir bash $script_path run >> $log_file 2>&1"
  (crontab -l 2>/dev/null | grep -v "env-baseline-daily-check.sh run" | grep -v '^CRON_TZ=' || true; \
   echo "CRON_TZ=Asia/Tokyo"; \
   echo "$schedule $command") | crontab -
  echo "Installed daily env baseline check: $schedule"
}

case "$mode" in
  run) run_check ;;
  install-cron) install_cron ;;
  *) echo "usage: $0 {run|install-cron}" >&2; exit 2 ;;
esac
