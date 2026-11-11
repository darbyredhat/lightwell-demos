#!/usr/bin/env bash
# Read-only checks before presenting Demo 1. Prints OK or FAIL per check; exits 1 if any check fails.
# Run from anywhere; paths are relative to this repo.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FEED="https://packages.redhat.com/lightwell/public-lightwell-demo/java/remediated"
FAILED=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "OK    $label"
  else
    echo "FAIL  $label"
    FAILED=1
  fi
}

feed_reachable() {
  [[ "$(curl -s -o /dev/null -w '%{http_code}' "$FEED/com/fasterxml/woodstox/woodstox-core/6.0.3.rhlw-00001/woodstox-core-6.0.3.rhlw-00001.pom")" == "200" ]]
}

check "python3 installed" command -v python3
check "cosign installed" command -v cosign
check "public Lightwell feed reachable (woodstox 6.0.3.rhlw-00001)" feed_reachable
check "app pom has woodstox 6.0.3" grep -q '<woodstox.version>6.0.3</woodstox.version>' "$REPO_ROOT/apps/payments-service/pom.xml"
check "no leftover /tmp/lw-scan (run the Reset command)" test ! -e /tmp/lw-scan

exit "$FAILED"
