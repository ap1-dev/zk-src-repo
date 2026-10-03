#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${APP_ROOT}/logs"

VANILLA_START=$(date +%s)

bash "${SCRIPT_DIR}/load_deps.sh"
bash "${SCRIPT_DIR}/compute_source_root.sh"

REGISTER_START=$(date +%s)
bash "${SCRIPT_DIR}/register_declared_deps.sh"
REGISTER_TIME=$(( $(date +%s) - REGISTER_START ))

bash "${SCRIPT_DIR}/build.sh"
bash "${SCRIPT_DIR}/run_tests.sh"
bash "${SCRIPT_DIR}/package_artifact.sh"

ARTIFACT_HASH_START=$(date +%s)
bash "${SCRIPT_DIR}/compute_artifact_hash.sh"
ARTIFACT_HASH_TIME=$(( $(date +%s) - ARTIFACT_HASH_START ))

VANILLA_END=$(date +%s)
VANILLA_ELAPSED=$(( VANILLA_END - VANILLA_START ))

# Subtract vcpkg registry fetch time if build.sh recorded it
VCPKG_FETCH_TIME=0
if [[ -f "${LOG_DIR}/vcpkg_fetch_time.txt" ]]; then
  VCPKG_FETCH_TIME=$(cat "${LOG_DIR}/vcpkg_fetch_time.txt")
fi

VANILLA_PURE=$(( VANILLA_ELAPSED - VCPKG_FETCH_TIME - REGISTER_TIME - ARTIFACT_HASH_TIME ))

echo "[VANILLA_BUILD] Completed successfully"
echo "[VANILLA_BUILD] Final summary: logs/final_build_summary.json"
echo "[VANILLA_BUILD] Artifact hash: dist/artifact_hash.txt"
echo ""
echo "[VANILLA_BUILD] --- Time Measurements ---"
echo "[VANILLA_BUILD] Total elapsed (inside container):       ${VANILLA_ELAPSED}s"
echo "[VANILLA_BUILD] vcpkg registry fetch time (excluded):   ${VCPKG_FETCH_TIME}s"
echo "[VANILLA_BUILD] register_declared_deps time (excluded): ${REGISTER_TIME}s"
echo "[VANILLA_BUILD] compute_artifact_hash time (excluded):  ${ARTIFACT_HASH_TIME}s"
echo "[VANILLA_BUILD] Pure build time (excl. above):          ${VANILLA_PURE}s"
