#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

OUTPUT="${DIST_DIR}/declared_source_root.txt"

# Build sorted array of leaf hashes: H(rel, file_hash) = sha256("rel|file_hash")
LEAVES=()
while IFS= read -r leaf; do
  LEAVES+=("$leaf")
done < <(
  find "${APP_ROOT}" \
    -type f \
    ! -path "${APP_ROOT}/build/*" \
    ! -path "${APP_ROOT}/dist/*" \
    ! -path "${APP_ROOT}/logs/*" \
    ! -path "${APP_ROOT}/vcpkg_installed/*" \
    ! -path "${APP_ROOT}/.vcpkg/*" \
    ! -path "${APP_ROOT}/commitments/*" \
    ! -name ".DS_Store" \
    | sort \
    | while read -r file; do
        rel="${file#${APP_ROOT}/}"
        file_hash="$(sha256_file "$file")"
        printf "%s" "${rel}|${file_hash}" | sha256_file /dev/stdin
      done
)

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

merkle_root "${LEAVES[@]}" > "${OUTPUT}"

DECLARED_SOURCE_ROOT="$(cat "${OUTPUT}")"
echo "declared_source_root=${DECLARED_SOURCE_ROOT}"

# Compute Poseidon commitment and write declared_source_root, r1, and
# declared_source_commitment to policy_register/declared_source.json.
COMMITMENTS_DIR="${APP_ROOT}/commitments"
DECLARED_SOURCE_JSON="${POLICY_REGISTER_DIR}/declared_source.json"

(
  cd "${COMMITMENTS_DIR}"
  if [[ ! -d node_modules ]]; then
    npm install --silent
  fi
  node scripts/register_declared_source.js "${DECLARED_SOURCE_ROOT}" "${DECLARED_SOURCE_JSON}"
)
