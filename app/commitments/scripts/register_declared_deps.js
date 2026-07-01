#!/usr/bin/env node
"use strict";

// Usage: node scripts/register_declared_deps.js <approved_deps_json_path> <output_json_path>
//
// Reads the approved dependency allowlist, sorts by name (so each dep's
// position in the tree is determined solely by its own key), then:
//   1. Encodes each dep as two field elements: encode(name), encode(version).
//   2. Computes leaf = Poseidon(encode(name), encode(version)) — collision-resistant,
//      ZK-native. The circuit proves "this opaque field element is in the tree";
//      the leaf-to-dep binding is enforced by TEE attestation, not the circuit.
//   3. Builds a Poseidon Merkle tree over the sorted leaves.
//   4. Generates a random r1, computes approved_deps_commitment = Poseidon(root, r1).
//   5. Writes root, r1, commitment, and per-dep Merkle paths (keyed by "name@version")
//      to policy_register/declared_deps.json.

const fs = require("fs");
const crypto = require("crypto");
const { buildPoseidon } = require("circomlibjs");

const FIELD_PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;

function randomFieldElement() {
  let r;
  do {
    r = BigInt("0x" + crypto.randomBytes(32).toString("hex")) % FIELD_PRIME;
  } while (r === 0n);
  return r;
}

// Encode an arbitrary string to a BN254 field element via polynomial rolling hash.
// This is just byte-to-field conversion — the collision-resistance comes from
// wrapping this in Poseidon at the leaf level.
function encodeToField(s) {
  let acc = 0n;
  for (let i = 0; i < s.length; i++) {
    acc = acc * 257n + BigInt(s.charCodeAt(i));
  }
  return acc % FIELD_PRIME;
}

function poseidonHash(poseidon, inputs) {
  return poseidon.F.toObject(poseidon(inputs));
}

// Fixed depth-3 tree over exactly 8 leaves — matches UsedDepsRoot8() in used_deps_root.circom
// and computeUsedDepsRoot() in tee_build.js.
const TREE_DEPTH = 3;
const MAX_DEPS   = 8; // 2 ** TREE_DEPTH

function buildMerkleTree(poseidon, leaves) {
  const padded = [...leaves];
  while (padded.length < MAX_DEPS) padded.push(0n);
  if (padded.length > MAX_DEPS) throw new Error(`Too many deps: max is ${MAX_DEPS}`);

  const levels = [padded];
  for (let d = 0; d < TREE_DEPTH; d++) {
    const prev = levels[d];
    const next = [];
    for (let i = 0; i < prev.length; i += 2) {
      next.push(poseidonHash(poseidon, [prev[i], prev[i + 1]]));
    }
    levels.push(next);
  }

  return { root: levels[TREE_DEPTH][0], levels };
}

function getMerklePath(tree, leafIndex) {
  const pathElements = [];
  const pathIndices = [];
  let index = leafIndex;
  for (let d = 0; d < TREE_DEPTH; d++) {
    pathElements.push(tree.levels[d][index ^ 1].toString());
    pathIndices.push(index % 2);
    index = Math.floor(index / 2);
  }
  return { pathElements, pathIndices };
}

async function main() {
  const approvedDepsPath = process.argv[2];
  const outputPath = process.argv[3];

  if (!approvedDepsPath || !outputPath) {
    console.error("Usage: node scripts/register_declared_deps.js <approved_deps_json> <output_json>");
    process.exit(1);
  }

  const approvedDeps = JSON.parse(fs.readFileSync(approvedDepsPath, "utf8")).approved_dependencies;

  // Sort by name so each dep's position is determined by its own key.
  const sorted = [...approvedDeps].sort((a, b) => a.name.localeCompare(b.name));

  const poseidon = await buildPoseidon();

  // Leaf = Poseidon(encode(name), encode(version))
  const leaves = sorted.map((dep) =>
    poseidonHash(poseidon, [encodeToField(dep.name), encodeToField(dep.version)])
  );

  if (sorted.length > MAX_DEPS) {
    console.error(`Too many approved deps: ${sorted.length} > MAX_DEPS (${MAX_DEPS})`);
    process.exit(1);
  }
  const tree = buildMerkleTree(poseidon, leaves);

  const approved_deps_root = tree.root.toString();
  const r1 = randomFieldElement();
  const approved_deps_commitment = poseidonHash(poseidon, [tree.root, r1]).toString();

  // Emit paths keyed by "name@version" for all approved deps.
  const paths = {};
  for (let i = 0; i < sorted.length; i++) {
    const key = `${sorted[i].name}@${sorted[i].version}`;
    paths[key] = {
      leaf: leaves[i].toString(),
      ...getMerklePath(tree, i),
    };
  }

  const output = {
    approved_deps_root,
    r1: r1.toString(),
    approved_deps_commitment,
    tree_depth: TREE_DEPTH,
    paths,
  };

  fs.mkdirSync(require("path").dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2) + "\n");

  console.log("approved_deps_root=" + approved_deps_root);
  console.log("r1=" + r1.toString());
  console.log("approved_deps_commitment=" + approved_deps_commitment);
  console.log("tree_depth=" + TREE_DEPTH);
  console.log("Written to " + outputPath);
}

main().catch((err) => { console.error(err); process.exit(1); });
