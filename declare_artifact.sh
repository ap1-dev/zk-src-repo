#!/usr/bin/env bash
set -euo pipefail

# Runs the vanilla build pipeline inside the same Linux container used by the
# TEE (tee-build:latest) so that declared_artifact.json is produced from an
# identical OS/toolchain. Commit the updated policy_register/declared_artifact.json
# after this script completes.
#
# Usage: ./declare_artifact.sh
# Prerequisite: docker image localhost:5000/tee-image-docker:latest must be available (push with: docker push localhost:5000/tee-image-docker:latest)

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

docker run --rm \
  -v "${REPO_DIR}:/repo" \
  -e VCPKG_ROOT=/opt/vcpkg \
  -e VCPKG_INSTALLED_DIR=/opt/vcpkg-installed \
  localhost:5000/tee-image-docker:latest \
  bash /repo/app/scripts/vanilla_build.sh

echo ""
echo "[declare_artifact] Done. Commit policy_register/declared_artifact.json."
