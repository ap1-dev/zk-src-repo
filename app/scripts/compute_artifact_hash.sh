#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

ARTIFACT="${DIST_DIR}/demo-hasher-linux-x64.tar.gz"
HASH_FILE="${DIST_DIR}/artifact_hash.txt"

sha256_file "${ARTIFACT}" > "${HASH_FILE}"

ARTIFACT_HASH="$(cat "${HASH_FILE}")"
echo "artifact_hash=${ARTIFACT_HASH}"

# Compute Poseidon commitment and write declared_artifact_root, r1, and
# declared_artifact_commitment to policy_register/declared_artifact.json.
COMMITMENTS_DIR="${APP_ROOT}/commitments"
DECLARED_ARTIFACT_JSON="${POLICY_REGISTER_DIR}/declared_artifact.json"

(
  cd "${COMMITMENTS_DIR}"
  if [[ ! -d node_modules ]]; then
    npm install --silent
  fi
  node scripts/register_declared_artifact.js "${ARTIFACT_HASH}" "${DECLARED_ARTIFACT_JSON}"
)
