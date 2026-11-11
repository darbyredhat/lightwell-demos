#!/usr/bin/env bash
# Downloads a Lightwell Maven artifact with its SBOM and provenance, verifies the SLSA provenance
# with cosign (Red Hat PNC Provenance Signing Key 1, from the Lightwell Configure guide), runs a
# tamper test, and summarizes the SBOM and provenance.
#
# Usage: demos/01-lightwell-walkthrough/verify-provenance.sh <group/path> <artifactId> <version>
# Example: demos/01-lightwell-walkthrough/verify-provenance.sh com/fasterxml/woodstox woodstox-core 6.0.3.rhlw-00001
#
# FEED (default: public demo remediated feed). For production, set
#   FEED=https://packages.redhat.com/lightwell/java/remediated  and  LW_USER / TOKEN.
set -euo pipefail

GROUP_PATH="${1:?group path, e.g. com/fasterxml/woodstox}"
ARTIFACT="${2:?artifactId, e.g. woodstox-core}"
VERSION="${3:?version, e.g. 6.0.3.rhlw-00001}"
FEED="${FEED:-https://packages.redhat.com/lightwell/public-lightwell-demo/java/remediated}"
WORK_DIR="$(mktemp -d /tmp/lw-provenance.XXXXXX)"
BASE="$FEED/$GROUP_PATH/$ARTIFACT/$VERSION"
NAME="$ARTIFACT-$VERSION"

AUTH=()
if [[ -n "${LW_USER:-}" && -n "${TOKEN:-}" ]]; then
  AUTH=(-u "$LW_USER:$TOKEN")
fi

command -v cosign >/dev/null || { echo "cosign is required (brew install cosign)" >&2; exit 1; }

echo "== Downloading from $BASE"
for file in "$NAME.jar" "$NAME.provenance.sigstore.json" "$NAME.cyclonedx.json" "$NAME.jar.asc"; do
  result=$(curl -s -L ${AUTH[@]+"${AUTH[@]}"} -o "$WORK_DIR/$file" -w '%{http_code} %{size_download}' "$BASE/$file")
  printf '   %-60s %s bytes\n' "$file" "$result"
done

cat > "$WORK_DIR/pnc-provenance-signing-key-1.pub" <<'EOF'
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYFyYXLNpOXF46lNdwKgOthCsOZ0W
5Uc29eO5IQzw2PKVkdpb781AZ/sUh7dSpe3hjjTu2brbjtOH1FWhO2Mmrg==
-----END PUBLIC KEY-----
EOF

verify() {
  cosign verify-blob-attestation \
    --type https://slsa.dev/provenance/v1 \
    --key "$WORK_DIR/pnc-provenance-signing-key-1.pub" \
    --bundle "$WORK_DIR/$NAME.provenance.sigstore.json" \
    "$1" 2>&1 | tail -1
}

echo "== Verify provenance (cosign)"
result=$(verify "$WORK_DIR/$NAME.jar" || true)
if [[ "$result" == "Verified OK" ]]; then
  echo "   PASS: the JAR matches Red Hat's signed provenance"
else
  echo "   FAIL: provenance did not verify"
fi
echo "   cosign: $result"

echo "== Tamper test (a copy of the JAR with one byte appended)"
cp "$WORK_DIR/$NAME.jar" "$WORK_DIR/tampered.jar"
printf 'x' >> "$WORK_DIR/tampered.jar"
result=$(verify "$WORK_DIR/tampered.jar" || true)
if [[ "$result" == *"digests do not match"* ]]; then
  echo "   PASS: the tampered copy is rejected, as expected"
else
  echo "   FAIL: the tampered copy was not rejected"
fi
echo "   cosign: $result"

echo "== SBOM and provenance summary"
python3 -I - "$WORK_DIR" "$NAME" <<'EOF'
import base64, json, sys
work_dir, name = sys.argv[1], sys.argv[2]
sbom = json.load(open(f"{work_dir}/{name}.cyclonedx.json"))
metadata = sbom.get("metadata", {})
component = metadata.get("component", {})
supplier = (metadata.get("supplier") or metadata.get("manufacture") or {}).get("name")
print(f"   SBOM: {sbom.get('bomFormat')} {sbom.get('specVersion')}, supplier {supplier}, "
      f"{component.get('name')} {component.get('version')}, {len(sbom.get('components', []))} components")
bundle = json.load(open(f"{work_dir}/{name}.provenance.sigstore.json"))
statement = json.loads(base64.b64decode(bundle["dsseEnvelope"]["payload"]))
predicate = statement.get("predicate", {})
print(f"   Provenance: {statement.get('predicateType')}")
print(f"   Builder: {predicate.get('runDetails', {}).get('builder', {}).get('id')}")
print(f"   Build type: {predicate.get('buildDefinition', {}).get('buildType')}")
EOF

echo "== Files kept in $WORK_DIR"
