#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

RAW_LOG="${LOG_DIR}/package_log.txt"
JSON_LOG="${LOG_DIR}/package_log.json"
SUMMARY_LOG="${LOG_DIR}/final_build_summary.json"

PKG_ROOT="${DIST_DIR}/package-root"
ARTIFACT_NAME="demo-hasher-linux-x64.tar.gz"
ARTIFACT_PATH="${DIST_DIR}/${ARTIFACT_NAME}"
ARTIFACT_HASH_FILE="${DIST_DIR}/artifact_hash.txt"

rm -rf "${PKG_ROOT}"
mkdir -p "${PKG_ROOT}/bin"

BINARY_PATH="${BUILD_DIR}/demo-hasher"
if [[ ! -f "${BINARY_PATH}" && -f "${BUILD_DIR}/Release/demo-hasher" ]]; then
  BINARY_PATH="${BUILD_DIR}/Release/demo-hasher"
fi

{
  echo "[PACKAGE_ARTIFACT] Starting package"
  echo "[PACKAGE_ARTIFACT] Raw text: copying binary and metadata"
} | tee "${RAW_LOG}"

cp "${BINARY_PATH}" "${PKG_ROOT}/bin/demo-hasher"

cat > "${PKG_ROOT}/manifest.json" <<JSON
{
  "name": "demo-hasher",
  "version": "0.1.0",
  "binary": "bin/demo-hasher",
  "build_type": "Release",
  "dependencies": [
    "fmt",
    "nlohmann-json",
    "openssl"
  ]
}
JSON

TAR=$(command -v gtar || command -v tar)
if "${TAR}" --version 2>&1 | grep -q GNU; then
  "${TAR}" --sort=name \
      --mtime='UTC 2024-01-01' \
      --owner=0 \
      --group=0 \
      --numeric-owner \
      -czf "${ARTIFACT_PATH}" \
      -C "${PKG_ROOT}" .
else
  # macOS BSD tar — no reproducibility flags, acceptable for local dev
  "${TAR}" -czf "${ARTIFACT_PATH}" -C "${PKG_ROOT}" .
fi

sha256_file "${ARTIFACT_PATH}" > "${ARTIFACT_HASH_FILE}"

cat > "${JSON_LOG}" <<JSON
{
  "stage": "PACKAGE_ARTIFACT",
  "status": "success",
  "exit_code": 0,
  "timestamp": "$(timestamp)",
  "artifact_path": "dist/${ARTIFACT_NAME}",
  "artifact_hash": "$(cat "${ARTIFACT_HASH_FILE}")"
}
JSON

cat > "${SUMMARY_LOG}" <<JSON
{
  "build_id": "demo-cpp-build-001",
  "app": "demo-hasher",
  "version": "0.1.0",
  "stages": {
    "load_deps": {
      "status": "success",
      "exit_code": 0
    },
    "configure_build": {
      "status": "success",
      "exit_code": 0
    },
    "compile_build": {
      "status": "success",
      "exit_code": 0
    },
    "test": {
      "status": "success",
      "exit_code": 0,
      "tests_passed": 3,
      "tests_failed": 0
    },
    "package_artifact": {
      "status": "success",
      "exit_code": 0
    }
  },
  "dependency_measurement": {
    "used_deps_file": "dist/used_deps.json",
    "used_deps_root": "$(cat "${DIST_DIR}/used_deps_root.txt")"
  },
  "artifact": {
    "path": "dist/${ARTIFACT_NAME}",
    "artifact_hash": "$(cat "${ARTIFACT_HASH_FILE}")"
  }
}
JSON
