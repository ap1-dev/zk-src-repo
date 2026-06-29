#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

RAW_LOG="${LOG_DIR}/deps_log.txt"
JSON_LOG="${LOG_DIR}/deps_log.json"
USED_DEPS="${DIST_DIR}/used_deps.json"

{
  echo "[LOAD_DEPS] Starting dependency loading"
  echo "[LOAD_DEPS] Reading vcpkg.json"
  echo "[LOAD_DEPS] Raw log: resolving fmt, nlohmann-json, openssl, catch2"
  echo "[LOAD_DEPS] In real pipeline, vcpkg install happens here"
  echo "[LOAD_DEPS] Completed"
} | tee "${RAW_LOG}"

cat > "${USED_DEPS}" <<'JSON'
{
  "used_dependencies": [
    {
      "name": "fmt",
      "version": "10.2.1"
    },
    {
      "name": "nlohmann-json",
      "version": "3.11.3"
    },
    {
      "name": "openssl",
      "version": "3.2.1"
    },
    {
      "name": "catch2",
      "version": "3.5.2"
    }
  ]
}
JSON

cat > "${JSON_LOG}" <<JSON
{
  "stage": "LOAD_DEPS",
  "status": "success",
  "exit_code": 0,
  "timestamp": "$(timestamp)",
  "used_deps_file": "dist/used_deps.json"
}
JSON
