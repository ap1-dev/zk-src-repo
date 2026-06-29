#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${APP_ROOT}/.." && pwd)"
POLICY_REGISTER_DIR="${REPO_ROOT}/policy_register"
BUILD_DIR="${APP_ROOT}/build"
DIST_DIR="${APP_ROOT}/dist"
LOG_DIR="${APP_ROOT}/logs"

mkdir -p "${BUILD_DIR}" "${DIST_DIR}" "${LOG_DIR}"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

merkle_root() {
  local -a level=("$@")

  if [[ ${#level[@]} -eq 0 ]]; then
    printf "%s" "EMPTY" | sha256_file /dev/stdin
    return
  fi

  while [[ ${#level[@]} -gt 1 ]]; do
    local -a nxt=()
    local i=0
    while [[ $i -lt ${#level[@]} ]]; do
      local left="${level[$i]}"
      local right
      if [[ $((i + 1)) -lt ${#level[@]} ]]; then
        right="${level[$((i + 1))]}"
      else
        right="$left"
      fi
      nxt+=( "$(printf "%s" "${left}|${right}" | sha256_file /dev/stdin)" )
      i=$((i + 2))
    done
    level=("${nxt[@]}")
  done

  echo "${level[0]}"
}
