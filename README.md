# zk-CICDv3 — Source Repo

A proof-of-concept for **verifiable CI/CD**: proving that a software artifact was built
from approved source code, using only approved dependencies, inside an attested Trusted
Execution Environment (TEE) — and backing that claim with a zero-knowledge (ZK) proof
instead of trust in the build server.

This repository holds the **application being built** plus the **policy register** of
cryptographic commitments that a downstream TEE build and ZK circuit verify against.

## The problem

When you download a binary, you trust that it was compiled from the source you think it
was, with the dependencies you approved, without tampering. Normally that trust rests
entirely on the CI/CD operator. This PoC replaces that trust with evidence: a build runs
inside a TEE, and a ZK proof attests that the build matched a pre-registered policy —
without revealing the private build inputs.

## What's in here

| Path | What it is |
|------|-----------|
| [app/](app/) | The demo application — `demo-hasher`, a small C++ CLI built with CMake + vcpkg (deps: `fmt`, `nlohmann-json`, `openssl`, `catch2`). |
| [app/scripts/](app/scripts/) | The **vanilla staged build pipeline**: `LOAD_DEPS → BUILD → TEST → PACKAGE`, emitting structured logs and a packaged artifact. |
| [app/commitments/](app/commitments/) | Node.js scripts that compute the ZK-native commitments (Poseidon Merkle trees over BN254) for source, dependencies, and artifact. |
| [policy_register/](policy_register/) | The **declared policy**: the committed roots/hashes the TEE build and ZK circuit check against. |
| [declare_artifact.sh](declare_artifact.sh) | Runs the vanilla build inside the TEE container image so `declared_artifact.json` is produced from an identical OS/toolchain. |

## The 5-stage verification model

The build measures five things, each mapped to a policy entry the ZK pipeline later proves:

```
S1  source root check       → app/ source tree       → declared_source.json
S2  dependency membership   → used vs. approved deps  → declared_deps.json / approved_deps.json
S3  build log check         → build_log.json          → (build succeeded)
S4  test log check          → test_log.json           → (tests passed)
S5  artifact hash check     → dist/artifact_hash.txt  → declared_artifact.json
```

The `policy_register/` files hold the committed form of these:

- **`declared_source.json`** — Poseidon commitment to the approved source-tree root.
- **`approved_deps.json`** — the human-readable allowlist of approved dependencies.
- **`declared_deps.json`** — a Poseidon Merkle tree over the approved deps, with per-dep
  Merkle paths. The circuit proves a used dependency is a member of this tree.
- **`declared_artifact.json`** — Poseidon commitment to the expected artifact hash.
- **`tee_measurement_policy.json`** — allowlist of attested TEE/ZK runner image measurements.

Each commitment follows the pattern `commitment = Poseidon(root, r1)`, where `r1` is a
random blinding factor — so the committed value can be published without revealing the
underlying root until a proof is produced.

## Building the app

Run the vanilla staged build:

```bash
cd app
bash scripts/vanilla_build.sh
```

It produces logs under `app/logs/` and a packaged artifact under `app/dist/`
(`demo-hasher-linux-x64.tar.gz`, `artifact_hash.txt`, `used_deps.json`, …).
See [app/README.md](app/README.md) for the full output list.

## Declaring the artifact (reproducible build)

To regenerate the declared artifact from an identical OS/toolchain, run the build inside
the TEE container image and commit the result:

```bash
./declare_artifact.sh
# then commit policy_register/declared_artifact.json
```

> Prerequisite: the TEE image `localhost:5000/tee-image-docker:latest` must be available.

## How the pieces fit together

```
app/ source  ──► vanilla_build.sh ──► artifact + logs + used_deps
     │                                        │
     ▼                                        ▼
commitments/ scripts ──────────────► policy_register/ (declared roots & commitments)
                                             │
                                             ▼
                      TEE build re-runs the pipeline under attestation,
                      ZK circuit proves it matched the declared policy
```

This repo is the **source + policy** half of that flow; the TEE build harness and ZK
circuits live alongside it in the broader `zk-CICDv3` project.
