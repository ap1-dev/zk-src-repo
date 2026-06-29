Run the vanilla staged build with:

```
cd app
bash scripts/vanilla_build.sh
```

It will produce:

```
app/logs/deps_log.json
app/logs/build_log.txt
app/logs/build_log.json
app/logs/test_log.json
app/logs/final_build_summary.json

app/dist/used_deps.json
app/dist/used_deps_root.txt
app/dist/demo-app.tar.gz
app/dist/artifact_hash.txt
```

The build has 4 logical stages internally:

```
LOAD_DEPS → BUILD → TEST → PACKAGE
```

For the 5-stage TEE + ZK pipeline, map them as:

```
S1 source root check       → app/ source tree
S2 dependency membership   → used_deps.json + approved_deps.json
S3 build log check         → build_log.json / build_log.txt
S4 test log check          → test_log.json
S5 artifact hash check     → dist/artifact_hash.txt
```