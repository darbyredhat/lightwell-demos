#!/usr/bin/env bash
# Sets up Xray for the Lightwell demo on a JFrog Platform instance:
#   1. Security policy lightwell-demo-security (all severities, no block or fail actions)
#   2. Watch lightwell-demo-watch on the Lightwell remotes and maven-central
#   3. Lightwell OSV advisories as Xray Custom Issues, using tools/lightwell-xray-sync
#      MODE=public: sync the public demo OSV feed (no Lightwell credentials)
#      MODE=prod:   push advisory files downloaded with LW_USER / TOKEN (OSV_FILES="file1.json ...")
#   4. Downloads the woodstox 6.0.3 and 6.0.3.rhlw-00001 JARs through acmebank_java_repo so Xray scans them
#
# Requires ART_URL, ART_USER, ART_TOKEN, and lightwell-xray-sync installed (see tools/lightwell-xray-sync/README.md).
# The watch API returns 400 on some instances; if so, create the watch in the UI (see setup.md).
set -euo pipefail

: "${ART_URL:?Set ART_URL}"
: "${ART_USER:?Set ART_USER}"
: "${ART_TOKEN:?Set ART_TOKEN}"
MODE="${MODE:-public}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SYNC_TOOL="${SYNC_TOOL:-$REPO_ROOT/tools/lightwell-xray-sync/.venv/bin/lightwell-xray-sync}"
POLICY=lightwell-demo-security
WATCH=lightwell-demo-watch
XRAY="$ART_URL/xray/api"

[[ -x "$SYNC_TOOL" ]] || { echo "lightwell-xray-sync not found at $SYNC_TOOL (see tools/lightwell-xray-sync/README.md)" >&2; exit 1; }

# Creates the resource with POST unless GET already finds it. Failures are reported, not fatal.
ensure() {
  local label="$1" get_url="$2" post_url="$3" body="$4" code
  code=$(curl -s -o /dev/null -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" "$get_url")
  if [[ "$code" == "200" ]]; then
    echo "SKIP  $label (already exists)"
    return
  fi
  code=$(curl -s -o /tmp/lw-setup-xray.out -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" \
    -X POST -H 'Content-Type: application/json' "$post_url" -d "$body")
  if [[ "$code" == 2* ]]; then
    echo "OK    $label ($code)"
  else
    echo "WARN  $label ($code): $(head -c 300 /tmp/lw-setup-xray.out)"
    echo "      Continuing. New repositories can take a few minutes to appear in Xray; rerun this script to retry."
  fi
}

echo "== 1. Policy"
ensure "policy $POLICY" "$XRAY/v2/policies/$POLICY" "$XRAY/v2/policies" "{
  \"name\": \"$POLICY\", \"type\": \"security\", \"description\": \"Lightwell demo: report all severities\",
  \"rules\": [{\"name\": \"any-severity\", \"priority\": 1,
    \"criteria\": {\"min_severity\": \"Low\"},
    \"actions\": {\"fail_build\": false, \"block_download\": {\"active\": false, \"unscanned\": false}}}]
}"

echo "== 2. Watch"
ensure "watch $WATCH" "$XRAY/v2/watches/$WATCH" "$XRAY/v2/watches" "{
  \"general_data\": {\"name\": \"$WATCH\", \"description\": \"Lightwell demo\", \"active\": true},
  \"project_resources\": {\"resources\": [
    {\"type\": \"repository\", \"bin_mgr_id\": \"default\", \"name\": \"lightwell-java-remediated\"},
    {\"type\": \"repository\", \"bin_mgr_id\": \"default\", \"name\": \"lightwell-java-validated\"},
    {\"type\": \"repository\", \"bin_mgr_id\": \"default\", \"name\": \"maven-central\"}]},
  \"assigned_policies\": [{\"name\": \"$POLICY\", \"type\": \"security\"}]
}"
rm -f /tmp/lw-setup-xray.out

echo "== 3. Lightwell OSV into Xray ($MODE)"
export JFROG_URL="$ART_URL" JFROG_USER="$ART_USER" JFROG_TOKEN="$ART_TOKEN"
cd /tmp
if [[ "$MODE" == "public" ]]; then
  "$SYNC_TOOL" sync --no-summary -v 2>&1 | grep -E 'SUCCESS|FAIL|ERROR|Done|Loaded'
else
  : "${OSV_FILES:?Set OSV_FILES to the advisory JSON files downloaded with LW_USER/TOKEN}"
  for file in $OSV_FILES; do
    "$SYNC_TOOL" push --input "$file" --no-summary -v 2>&1 | grep -E 'SUCCESS|FAIL|ERROR|Done'
  done
fi
cd - > /dev/null

echo "== 4. Cache woodstox JARs through acmebank_java_repo (code bytes)"
for version in 6.0.3 6.0.3.rhlw-00001; do
  result=$(curl -s -L -o /dev/null -w '%{http_code} %{size_download}' -u "$ART_USER:$ART_TOKEN" \
    "$ART_URL/artifactory/acmebank_java_repo/com/fasterxml/woodstox/woodstox-core/$version/woodstox-core-$version.jar")
  echo "   woodstox-core $version: $result"
done
echo "Xray scans new artifacts within a few minutes."
