#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

APPROVED_DEPS="${POLICY_REGISTER_DIR}/approved_deps.json"
DECLARED_DEPS_JSON="${POLICY_REGISTER_DIR}/declared_deps.json"

COMMITMENTS_DIR="${APP_ROOT}/commitments"
(
  cd "${COMMITMENTS_DIR}"
  if [[ ! -d node_modules ]]; then
    npm install --silent
  fi
  node scripts/register_declared_deps.js "${APPROVED_DEPS}" "${DECLARED_DEPS_JSON}"
)
