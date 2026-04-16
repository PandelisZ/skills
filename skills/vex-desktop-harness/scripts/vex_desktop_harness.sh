#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${VEX_REPO_ROOT:-/Users/pz/w/vex}"
DESKTOP_DIR="${REPO_ROOT}/desktop"
STATE_HASH="$(printf '%s' "${DESKTOP_DIR}" | cksum | awk '{print $1}')"
TMP_ROOT="${TMPDIR:-/tmp}"
STATE_DIR="${TMP_ROOT%/}/vex-desktop-harness-${STATE_HASH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_SCRIPT="${SCRIPT_DIR}/vex_desktop_harness_helper.py"
mkdir -p "${STATE_DIR}"

STORYBOOK_PORT="${STORYBOOK_PORT:-6006}"
VITE_PORT="${VITE_PORT:-1420}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") status
  $(basename "$0") paths
  $(basename "$0") doctor
  $(basename "$0") artifacts
  $(basename "$0") build [desktop|storybook|tauri]
  $(basename "$0") start [storybook|vite|tauri-dev]
  $(basename "$0") smoke [storybook --story <story-id-or-title>|vite|tauri-dev]
  $(basename "$0") stop [storybook|vite|tauri-dev|all]
  $(basename "$0") logs [storybook|vite|tauri-dev] [lines]
  $(basename "$0") wait [storybook|vite|tauri-dev] [timeout-seconds]

Environment:
  VEX_REPO_ROOT   Override repo root (default: /Users/pz/w/vex)
  STORYBOOK_PORT  Storybook port (default: 6006)
  VITE_PORT       Vite dev port (default: 1420)
EOF
}

service_pid_file() {
  printf '%s/%s.pid\n' "${STATE_DIR}" "$1"
}

service_log_file() {
  printf '%s/%s.log\n' "${STATE_DIR}" "$1"
}

service_port() {
  case "$1" in
    storybook)
      printf '%s\n' "${STORYBOOK_PORT}"
      ;;
    vite|tauri-dev)
      printf '%s\n' "${VITE_PORT}"
      ;;
    *)
      return 1
      ;;
  esac
}

service_url() {
  case "$1" in
    storybook)
      printf 'http://localhost:%s\n' "${STORYBOOK_PORT}"
      ;;
    vite)
      printf 'http://127.0.0.1:%s\n' "${VITE_PORT}"
      ;;
    tauri-dev)
      printf 'http://localhost:%s\n' "${VITE_PORT}"
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_desktop_dir() {
  if [[ ! -d "${DESKTOP_DIR}" ]]; then
    echo "Desktop directory not found: ${DESKTOP_DIR}" >&2
    exit 1
  fi
}

ensure_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "required command not found: ${command_name}" >&2
    exit 1
  fi
}

run_helper() {
  ensure_command "python3"
  python3 "${HELPER_SCRIPT}" \
    --repo-root "${REPO_ROOT}" \
    --desktop-dir "${DESKTOP_DIR}" \
    --state-dir "${STATE_DIR}" \
    --storybook-port "${STORYBOOK_PORT}" \
    --vite-port "${VITE_PORT}" \
    "$@"
}

is_running() {
  local service="$1"
  local pid_file
  pid_file="$(service_pid_file "${service}")"
  if [[ ! -f "${pid_file}" ]]; then
    return 1
  fi

  local pid
  pid="$(cat "${pid_file}")"
  if [[ -z "${pid}" ]]; then
    return 1
  fi

  if kill -0 "${pid}" >/dev/null 2>&1; then
    return 0
  fi

  rm -f "${pid_file}"
  return 1
}

service_ready() {
  local service="$1"
  case "${service}" in
    storybook)
      is_port_listening "${STORYBOOK_PORT}"
      ;;
    vite)
      is_port_listening "${VITE_PORT}"
      ;;
    tauri-dev)
      is_running "tauri-dev" && is_port_listening "${VITE_PORT}"
      ;;
    *)
      return 1
      ;;
  esac
}

print_service_status() {
  local service="$1"
  local pid_file
  local log_file
  pid_file="$(service_pid_file "${service}")"
  log_file="$(service_log_file "${service}")"

  if is_running "${service}"; then
    printf '%s: running (pid %s)\n' "${service}" "$(cat "${pid_file}")"
  else
    printf '%s: stopped\n' "${service}"
  fi

  printf '  pid file: %s\n' "${pid_file}"
  printf '  log: %s\n' "${log_file}"

  if service_port "${service}" >/dev/null 2>&1; then
    printf '  port: %s\n' "$(service_port "${service}")"
    printf '  url: %s\n' "$(service_url "${service}")"
  fi

  if service_ready "${service}"; then
    echo "  ready: yes"
  else
    echo "  ready: no"
  fi
}

is_port_listening() {
  local port="$1"
  lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
}

print_port_status() {
  local label="$1"
  local port="$2"
  if is_port_listening "${port}"; then
    printf '%s port %s: listening\n' "${label}" "${port}"
  else
    printf '%s port %s: not listening\n' "${label}" "${port}"
  fi
}

start_storybook() {
  if is_running "storybook"; then
    echo "storybook already running"
    return
  fi

  if is_port_listening "${STORYBOOK_PORT}"; then
    echo "storybook port ${STORYBOOK_PORT} already has a listener outside this harness"
    return
  fi

  ensure_desktop_dir
  local log_file
  log_file="$(service_log_file "storybook")"
  nohup bash -lc "cd '${DESKTOP_DIR}' && pnpm exec storybook dev --config-dir .storybook --port '${STORYBOOK_PORT}'" \
    >"${log_file}" 2>&1 &
  echo "$!" >"$(service_pid_file "storybook")"
  echo "storybook started on http://localhost:${STORYBOOK_PORT}"
  echo "log: ${log_file}"
}

start_vite() {
  if is_running "vite"; then
    echo "vite already running"
    return
  fi

  if is_running "tauri-dev"; then
    echo "tauri-dev is already running and owns port ${VITE_PORT}; stop it before starting vite" >&2
    exit 1
  fi

  if is_port_listening "${VITE_PORT}"; then
    echo "vite port ${VITE_PORT} already has a listener outside this harness"
    return
  fi

  ensure_desktop_dir
  local log_file
  log_file="$(service_log_file "vite")"
  nohup bash -lc "cd '${DESKTOP_DIR}' && pnpm exec vite --host 127.0.0.1 --port '${VITE_PORT}'" \
    >"${log_file}" 2>&1 &
  echo "$!" >"$(service_pid_file "vite")"
  echo "vite started on http://127.0.0.1:${VITE_PORT}"
  echo "log: ${log_file}"
  echo "wait: $(basename "$0") wait vite"
}

start_tauri_dev() {
  if is_running "tauri-dev"; then
    echo "tauri-dev already running"
    return
  fi

  if is_running "vite"; then
    echo "vite is already running under this harness; tauri-dev launches its own Vite dev server and would conflict on port ${VITE_PORT}" >&2
    exit 1
  fi

  if is_port_listening "${VITE_PORT}"; then
    echo "vite port ${VITE_PORT} already has a listener outside this harness; tauri-dev will fail while its beforeDevCommand tries to bind that port" >&2
    exit 1
  fi

  ensure_desktop_dir
  local log_file
  log_file="$(service_log_file "tauri-dev")"
  nohup bash -lc "cd '${DESKTOP_DIR}' && pnpm tauri dev" >"${log_file}" 2>&1 &
  echo "$!" >"$(service_pid_file "tauri-dev")"
  echo "tauri-dev started"
  echo "log: ${log_file}"
  echo "wait: $(basename "$0") wait tauri-dev 90"
}

stop_service() {
  local service="$1"
  if ! is_running "${service}"; then
    echo "${service} already stopped"
    return
  fi

  local pid
  pid="$(cat "$(service_pid_file "${service}")")"
  kill "${pid}" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    if ! kill -0 "${pid}" >/dev/null 2>&1; then
      rm -f "$(service_pid_file "${service}")"
      echo "${service} stopped"
      return
    fi
    sleep 0.25
  done
  kill -9 "${pid}" >/dev/null 2>&1 || true
  rm -f "$(service_pid_file "${service}")"
  echo "${service} stopped (forced)"
}

show_logs() {
  local service="$1"
  local lines="${2:-50}"
  local log_file
  log_file="$(service_log_file "${service}")"
  if [[ ! -f "${log_file}" ]]; then
    echo "no log file for ${service}" >&2
    exit 1
  fi
  tail -n "${lines}" "${log_file}"
}

wait_for_service() {
  local service="$1"
  local timeout="${2:-60}"
  local started_at
  started_at="$(date +%s)"

  while true; do
    if service_ready "${service}"; then
      printf '%s ready: %s\n' "${service}" "$(service_url "${service}")"
      printf 'log: %s\n' "$(service_log_file "${service}")"
      return
    fi

    if [[ "${service}" == "tauri-dev" || "${service}" == "vite" || "${service}" == "storybook" ]]; then
      if ! is_running "${service}" && [[ ! -f "$(service_log_file "${service}")" ]]; then
        echo "${service} has not been started by this harness and is not ready" >&2
        exit 1
      fi
      if [[ -f "$(service_log_file "${service}")" ]] && ! is_running "${service}" && ! service_ready "${service}"; then
        echo "${service} exited before becoming ready" >&2
        show_logs "${service}" 120 || true
        exit 1
      fi
    fi

    local now
    now="$(date +%s)"
    if (( now - started_at >= timeout )); then
      echo "${service} did not become ready within ${timeout}s" >&2
      if [[ -f "$(service_log_file "${service}")" ]]; then
        show_logs "${service}" 120 || true
      fi
      exit 1
    fi

    sleep 1
  done
}

run_build() {
  local target="${1:-desktop}"
  ensure_desktop_dir

  case "${target}" in
    desktop)
      (cd "${DESKTOP_DIR}" && pnpm build)
      ;;
    storybook)
      (cd "${DESKTOP_DIR}" && pnpm build-storybook)
      ;;
    tauri)
      (cd "${DESKTOP_DIR}" && pnpm tauri build)
      ;;
    *)
      echo "unknown build target: ${target}" >&2
      exit 1
      ;;
  esac
}

show_status() {
  ensure_desktop_dir
  printf 'repo: %s\n' "${REPO_ROOT}"
  printf 'desktop: %s\n' "${DESKTOP_DIR}"
  printf 'state: %s\n' "${STATE_DIR}"
  print_service_status "storybook"
  print_service_status "vite"
  print_service_status "tauri-dev"
  print_port_status "storybook" "${STORYBOOK_PORT}"
  print_port_status "vite" "${VITE_PORT}"
  if ! is_running "storybook" && is_port_listening "${STORYBOOK_PORT}"; then
    echo "storybook note: listener exists but is not managed by this harness"
  fi
  if ! is_running "vite" && is_port_listening "${VITE_PORT}"; then
    echo "vite note: listener exists but is not managed by this harness"
  fi
  if is_running "tauri-dev"; then
    echo "tauri-dev note: the app boot is considered ready when the dev process is alive and port ${VITE_PORT} is listening"
  fi
}

main() {
  local command="${1:-}"
  case "${command}" in
    status)
      show_status
      ;;
    paths)
      run_helper paths
      ;;
    doctor)
      run_helper doctor
      ;;
    artifacts)
      run_helper artifacts
      ;;
    build)
      run_build "${2:-desktop}"
      ;;
    start)
      case "${2:-}" in
        storybook) start_storybook ;;
        vite) start_vite ;;
        tauri-dev) start_tauri_dev ;;
        *) usage; exit 1 ;;
      esac
      ;;
    smoke)
      shift
      run_helper smoke "$@"
      ;;
    stop)
      case "${2:-}" in
        storybook) stop_service "storybook" ;;
        vite) stop_service "vite" ;;
        tauri-dev) stop_service "tauri-dev" ;;
        all)
          stop_service "tauri-dev"
          stop_service "vite"
          stop_service "storybook"
          ;;
        *) usage; exit 1 ;;
      esac
      ;;
    logs)
      case "${2:-}" in
        storybook|vite|tauri-dev) show_logs "${2}" "${3:-50}" ;;
        *) usage; exit 1 ;;
      esac
      ;;
    wait)
      case "${2:-}" in
        storybook|vite|tauri-dev) wait_for_service "${2}" "${3:-60}" ;;
        *) usage; exit 1 ;;
      esac
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
