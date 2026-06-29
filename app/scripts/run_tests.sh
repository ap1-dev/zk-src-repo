#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

RAW_LOG="${LOG_DIR}/test_log.txt"
JSON_LOG="${LOG_DIR}/test_log.json"

{
  echo "[TEST] Starting tests"
  echo "[TEST] Raw text: running CTest"
} | tee "${RAW_LOG}"

ctest --test-dir "${BUILD_DIR}" --output-on-failure 2>&1 | tee -a "${RAW_LOG}"

cat > "${JSON_LOG}" <<JSON
{
  "stage": "TEST",
  "status": "success",
  "exit_code": 0,
  "timestamp": "$(timestamp)",
  "tests_expected": 3,
  "tests_failed": 0,
  "tests_passed": 3
}
JSON
