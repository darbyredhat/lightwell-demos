#!/usr/bin/env bash
# Creates or updates the Lightwell repositories on a JFrog Platform instance, using the names and
# remote settings from Anurag Saran's lightwell-integrations/artifactory/README.md:
#   lightwell-java-remediated, lightwell-java-validated, maven-central  (remote, Xray-indexed)
#   lightwell-java      (virtual: remediated, then validated)
#   acmebank_java_repo  (virtual: lightwell-java, then maven-central)
#
# Usage: demos/02-artifactory-xray/setup-repos.sh             (public demo feeds, no Lightwell credentials)
#        MODE=prod demos/02-artifactory-xray/setup-repos.sh   (production feeds; needs LW_USER and TOKEN)
# Requires ART_URL, ART_USER, ART_TOKEN. Prints no secrets.
set -euo pipefail

: "${ART_URL:?Set ART_URL, for example https://<your-instance>.jfrog.io}"
: "${ART_USER:?Set ART_USER}"
: "${ART_TOKEN:?Set ART_TOKEN}"
MODE="${MODE:-public}"

case "$MODE" in
  public)
    LIGHTWELL_BASE="https://packages.redhat.com/lightwell/public-lightwell-demo/java"
    REMOTE_USER=""
    REMOTE_PASSWORD=""
    ;;
  prod)
    : "${LW_USER:?Set LW_USER (Lightwell registry service account) for MODE=prod}"
    : "${TOKEN:?Set TOKEN (Lightwell registry service account token) for MODE=prod}"
    LIGHTWELL_BASE="https://packages.redhat.com/lightwell/java"
    REMOTE_USER="$LW_USER"
    REMOTE_PASSWORD="$TOKEN"
    ;;
  *)
    echo "MODE must be public or prod (got $MODE)" >&2
    exit 2
    ;;
esac

API="$ART_URL/artifactory/api/repositories"

remote_json() {
  python3 -I -c '
import json, sys
key, url, user, password = sys.argv[1:5]
print(json.dumps({
    "key": key, "rclass": "remote", "packageType": "maven", "url": url,
    "username": user, "password": password,
    "repoLayoutRef": "maven-2-default",
    "handleReleases": True, "handleSnapshots": False,
    "listRemoteFolderItems": True,
    "enableTokenAuthentication": False,
    "bypassHeadRequests": True,
    "missedRetrievalCachePeriodSecs": 600,
    "metadataRetrievalCachePeriodSecs": 600,
    "retrievalCachePeriodSecs": 7200,
    "xrayIndex": True,
}))' "$@"
}

virtual_json() {
  python3 -I -c '
import json, sys
key, members = sys.argv[1], sys.argv[2:]
print(json.dumps({"key": key, "rclass": "virtual", "packageType": "maven", "repositories": members}))' "$@"
}

# PUT creates a repository; POST updates an existing one.
apply_repo() {
  local key="$1" body="$2" method code
  code=$(curl -s -o /dev/null -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" "$API/$key")
  if [[ "$code" == "200" ]]; then method=POST; else method=PUT; fi
  code=$(curl -s -o /tmp/lw-setup-repos.out -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" \
    -X "$method" -H 'Content-Type: application/json' "$API/$key" -d "$body")
  if [[ "$code" == 2* ]]; then
    echo "OK    $method $key ($code)"
  else
    echo "FAIL  $method $key ($code): $(head -c 300 /tmp/lw-setup-repos.out)"
    exit 1
  fi
}

echo "== Mode: $MODE ($LIGHTWELL_BASE)"
apply_repo lightwell-java-remediated "$(remote_json lightwell-java-remediated "$LIGHTWELL_BASE/remediated/" "$REMOTE_USER" "$REMOTE_PASSWORD")"
apply_repo lightwell-java-validated "$(remote_json lightwell-java-validated "$LIGHTWELL_BASE/validated/" "$REMOTE_USER" "$REMOTE_PASSWORD")"
# Reuse an existing maven-central without changing it (it may be shared on this instance).
if [[ "$(curl -s -o /dev/null -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" "$API/maven-central")" == "200" ]]; then
  echo "SKIP  maven-central (already exists; left unchanged)"
else
  apply_repo maven-central "$(remote_json maven-central "https://repo1.maven.org/maven2/" "" "")"
fi
apply_repo lightwell-java "$(virtual_json lightwell-java lightwell-java-remediated lightwell-java-validated)"
apply_repo acmebank_java_repo "$(virtual_json acmebank_java_repo lightwell-java maven-central)"
rm -f /tmp/lw-setup-repos.out

echo "== Saved settings"
for key in lightwell-java-remediated lightwell-java-validated maven-central lightwell-java acmebank_java_repo; do
  curl -s -u "$ART_USER:$ART_TOKEN" "$API/$key" | python3 -I -c '
import json, sys
r = json.load(sys.stdin)
if r.get("rclass") == "virtual":
    print("   %-27s virtual  members=%s" % (r["key"], r.get("repositories")))
else:
    print("   %-27s remote   url=%s user=%s listRemote=%s bypassHead=%s missedCache=%s xrayIndex=%s" % (
        r["key"], r.get("url"), "set" if r.get("username") else "none", r.get("listRemoteFolderItems"),
        r.get("bypassHeadRequests"), r.get("missedRetrievalCachePeriodSecs"), r.get("xrayIndex")))'
done
