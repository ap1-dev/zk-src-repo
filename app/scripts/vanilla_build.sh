#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "${SCRIPT_DIR}/load_deps.sh"
bash "${SCRIPT_DIR}/compute_source_root.sh"
bash "${SCRIPT_DIR}/register_declared_deps.sh"
bash "${SCRIPT_DIR}/build.sh"
bash "${SCRIPT_DIR}/run_tests.sh"
bash "${SCRIPT_DIR}/package_artifact.sh"
bash "${SCRIPT_DIR}/compute_artifact_hash.sh"

echo "[VANILLA_BUILD] Completed successfully"
echo "[VANILLA_BUILD] Final summary: logs/final_build_summary.json"
echo "[VANILLA_BUILD] Artifact hash: dist/artifact_hash.txt"
