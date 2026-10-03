#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

CONFIGURE_RAW_LOG="${LOG_DIR}/configure_log.txt"
CONFIGURE_JSON_LOG="${LOG_DIR}/configure_log.json"
BUILD_RAW_LOG="${LOG_DIR}/build_log.txt"
BUILD_JSON_LOG="${LOG_DIR}/build_log.json"

{
  echo "[CONFIGURE_BUILD] Starting CMake configure"
  echo "[CONFIGURE_BUILD] Raw text: generating build files"
  echo "[CONFIGURE_BUILD] Using CMAKE_BUILD_TYPE=Release"
} | tee "${CONFIGURE_RAW_LOG}"

rm -rf "${BUILD_DIR}"

export SOURCE_DATE_EPOCH=0

CMAKE_ARGS=(
  -S "${APP_ROOT}"
  -B "${BUILD_DIR}"
  -DCMAKE_BUILD_TYPE=Release
)

if [[ -n "${VCPKG_ROOT:-}" ]]; then
  CMAKE_ARGS+=(
    "-DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
    "-DVCPKG_MANIFEST_DIR=${APP_ROOT}"
    "-DVCPKG_INSTALLED_DIR=${APP_ROOT}/vcpkg_installed"
  )
  echo "[CONFIGURE_BUILD] VCPKG_ROOT detected: ${VCPKG_ROOT}" | tee -a "${CONFIGURE_RAW_LOG}"

  # Time the vcpkg registry fetch (network I/O) separately so vanilla_build.sh
  # can subtract it from the total and report a network-free build time.
  echo "[CONFIGURE_BUILD] Fetching vcpkg registry (timed separately) ..." | tee -a "${CONFIGURE_RAW_LOG}"
  VCPKG_FETCH_START=$(date +%s)
  "${VCPKG_ROOT}/vcpkg" install \
    --x-manifest-root="${APP_ROOT}" \
    --x-install-root="${APP_ROOT}/vcpkg_installed" \
    2>&1 | tee -a "${CONFIGURE_RAW_LOG}"
  VCPKG_FETCH_END=$(date +%s)
  VCPKG_FETCH_ELAPSED=$(( VCPKG_FETCH_END - VCPKG_FETCH_START ))
  echo "${VCPKG_FETCH_ELAPSED}" > "${LOG_DIR}/vcpkg_fetch_time.txt"
  echo "[CONFIGURE_BUILD] vcpkg fetch time: ${VCPKG_FETCH_ELAPSED}s" | tee -a "${CONFIGURE_RAW_LOG}"
else
  echo "[CONFIGURE_BUILD] VCPKG_ROOT not set; expecting system packages or preconfigured toolchain" | tee -a "${CONFIGURE_RAW_LOG}"
fi

cmake "${CMAKE_ARGS[@]}" 2>&1 | tee -a "${CONFIGURE_RAW_LOG}"

cat > "${CONFIGURE_JSON_LOG}" <<JSON
{
  "stage": "CONFIGURE_BUILD",
  "status": "success",
  "exit_code": 0,
  "timestamp": "$(timestamp)"
}
JSON

{
  echo "[COMPILE_BUILD] Starting compile"
  echo "[COMPILE_BUILD] Raw text: compiling C++ files and linking dependencies"
} | tee "${BUILD_RAW_LOG}"

cmake --build "${BUILD_DIR}" --config Release 2>&1 | tee -a "${BUILD_RAW_LOG}"

cat > "${BUILD_JSON_LOG}" <<JSON
{
  "stage": "COMPILE_BUILD",
  "status": "success",
  "exit_code": 0,
  "timestamp": "$(timestamp)",
  "binary": "build/demo-hasher"
}
JSON
