#!/usr/bin/env bash
# Adds an Xray ignore rule for JFrog's own finding on a Lightwell build that Red Hat has fixed.
#
# Why this is needed: JFrog's vulnerability data matches by version number. It reads
# woodstox-core 6.0.3.rhlw-00001 as below the upstream fix (6.4.0), so its issue XRAY-255585
# (CVE-2022-40152) still flags the Lightwell build. Red Hat's Lightwell advisory
# x_RHLW-CVE-2022-40152-6.0.3 records this exact build as the fix, but a Custom Issue only adds
# Red Hat's view; it can't override JFrog's entry. The ignore rule records that decision once.
#
# Defaults are for woodstox; override with ISSUE, COMPONENT, VERSION, ADVISORY.
# Requires ART_URL, ART_USER, ART_TOKEN.
set -euo pipefail

: "${ART_URL:?Set ART_URL}"
: "${ART_USER:?Set ART_USER}"
: "${ART_TOKEN:?Set ART_TOKEN}"
ISSUE="${ISSUE:-XRAY-255585}"
COMPONENT="${COMPONENT:-gav://com.fasterxml.woodstox:woodstox-core}"
VERSION="${VERSION:-6.0.3.rhlw-00001}"
ADVISORY="${ADVISORY:-x_RHLW-CVE-2022-40152-6.0.3}"
RULES="$ART_URL/xray/api/v1/ignore_rules"

existing=$(curl -s -u "$ART_USER:$ART_TOKEN" "$RULES" | python3 -I -c '
import json, sys
issue, component, version = sys.argv[1:4]
data = json.load(sys.stdin)
rules = data.get("data", []) if isinstance(data, dict) else data
for rule in rules:
    filters = rule.get("ignore_filters", {})
    components = filters.get("components", [])
    if issue in filters.get("vulnerabilities", []) and any(
            c.get("name") == component and c.get("version") == version for c in components):
        print(rule.get("id", "existing"))
        break' "$ISSUE" "$COMPONENT" "$VERSION")

if [[ -n "$existing" ]]; then
  echo "SKIP  ignore rule for $ISSUE on $COMPONENT:$VERSION (already exists: $existing)"
  exit 0
fi

body=$(python3 -I -c '
import json, sys
issue, component, version, advisory = sys.argv[1:5]
print(json.dumps({
    "notes": (f"Lightwell build: Red Hat advisory {advisory} records {version} as the fix for this CVE. "
              "JFrog data matches by version number and does not know about the Lightwell backport."),
    "ignore_filters": {"vulnerabilities": [issue], "components": [{"name": component, "version": version}]},
}))' "$ISSUE" "$COMPONENT" "$VERSION" "$ADVISORY")

code=$(curl -s -o /tmp/lw-ignore-rule.out -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" \
  -X POST -H 'Content-Type: application/json' "$RULES" -d "$body")
if [[ "$code" == 2* ]]; then
  echo "OK    ignore rule for $ISSUE on $COMPONENT:$VERSION ($code): $(head -c 200 /tmp/lw-ignore-rule.out)"
else
  echo "FAIL  ignore rule ($code): $(head -c 300 /tmp/lw-ignore-rule.out)"
  rm -f /tmp/lw-ignore-rule.out
  exit 1
fi
rm -f /tmp/lw-ignore-rule.out
