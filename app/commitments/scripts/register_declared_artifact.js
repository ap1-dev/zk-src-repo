#!/usr/bin/env node
"use strict";

// Usage: node scripts/register_declared_artifact.js <declared_artifact_root_hex> <output_json_path>
//
// Generates a random r1 field element, computes:
//   declared_artifact_commitment = Poseidon(declared_artifact_root, r1)
// and writes declared_artifact_root, r1, and declared_artifact_commitment to the output JSON.

const fs = require("fs");
const crypto = require("crypto");
const { buildPoseidon } = require("circomlibjs");

// BN254 scalar field prime
const FIELD_PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;

function randomFieldElement() {
  let r;
  do {
    r = BigInt("0x" + crypto.randomBytes(32).toString("hex")) % FIELD_PRIME;
  } while (r === 0n);
  return r;
}

async function main() {
  const rootHex = process.argv[2];
  const outputPath = process.argv[3];

  if (!rootHex || !outputPath) {
    console.error("Usage: node scripts/register_declared_artifact.js <declared_artifact_root_hex> <output_json_path>");
    process.exit(1);
  }

  const poseidon = await buildPoseidon();
  const F = poseidon.F;

  // Reduce hex SHA256 root into BN254 field
  const declared_artifact_root_poseidon = BigInt("0x" + rootHex) % FIELD_PRIME;
  const r1 = randomFieldElement();

  const commitment = poseidon([declared_artifact_root_poseidon, r1]);
  const declared_artifact_commitment = F.toString(commitment);

  const output = {
    declared_artifact_root: rootHex,
    declared_artifact_root_poseidon: declared_artifact_root_poseidon.toString(),
    r1: r1.toString(),
    declared_artifact_commitment,
  };

  fs.mkdirSync(require("path").dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2) + "\n");

  console.log("declared_artifact_root=" + rootHex);
  console.log("declared_artifact_root_poseidon=" + declared_artifact_root_poseidon.toString());
  console.log("r1=" + r1.toString());
  console.log("declared_artifact_commitment=" + declared_artifact_commitment);
  console.log("Written to " + outputPath);
}

main().catch((err) => { console.error(err); process.exit(1); });
