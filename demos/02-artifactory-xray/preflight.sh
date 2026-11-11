#!/usr/bin/env bash
# Read-only checks before presenting Demo 2. Prints OK or FAIL per check; exits 1 if any check fails.
# Requires ART_URL, ART_USER, ART_TOKEN. Prints no secrets.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAILED=0

ok()   { echo "OK    $1"; }
fail() { echo "FAIL  $1"; FAILED=1; }

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi
}

for var in ART_URL ART_USER ART_TOKEN; do
  if [[ -n "${!var:-}" ]]; then ok "$var set"; else fail "$var set"; fi
done
check "mvn installed" command -v mvn
check "app pom has woodstox 6.0.3 (run the Reset command if not)" grep -q '<woodstox.version>6.0.3</woodstox.version>' "$REPO_ROOT/apps/payments-service/pom.xml"

if [[ -z "${ART_URL:-}" || -z "${ART_USER:-}" || -z "${ART_TOKEN:-}" ]]; then
  echo "Skipping instance checks: set the JFrog variables first."
  exit 1
fi

http_code() { curl -s -L -o /dev/null -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" "$1"; }

for version in 6.0.3 6.0.3.rhlw-00001; do
  code=$(http_code "$ART_URL/artifactory/acmebank_java_repo/com/fasterxml/woodstox/woodstox-core/$version/woodstox-core-$version.jar")
  if [[ "$code" == "200" ]]; then ok "woodstox-core $version through acmebank_java_repo"; else fail "woodstox-core $version through acmebank_java_repo ($code)"; fi
done

code=$(http_code "$ART_URL/xray/api/v2/watches/lightwell-demo-watch")
if [[ "$code" == "200" ]]; then ok "watch lightwell-demo-watch exists"; else fail "watch lightwell-demo-watch exists ($code)"; fi

rule=$(curl -s -u "$ART_USER:$ART_TOKEN" "$ART_URL/xray/api/v1/ignore_rules" | python3 -I -c '
import json, sys
try:
    data = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
rules = data.get("data", []) if isinstance(data, dict) else data
for rule in rules:
    filters = rule.get("ignore_filters", {})
    if "XRAY-255585" in filters.get("vulnerabilities", []) and any(
            c.get("version") == "6.0.3.rhlw-00001" for c in filters.get("components", [])):
        print("found")
        break')
if [[ "$rule" == "found" ]]; then ok "ignore rule for XRAY-255585 on 6.0.3.rhlw-00001 exists"; else fail "ignore rule for XRAY-255585 on 6.0.3.rhlw-00001 exists"; fi

exit "$FAILED"
