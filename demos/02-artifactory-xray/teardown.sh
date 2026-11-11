#!/usr/bin/env bash
# Deletes the Lightwell demo repositories created by setup-repos.sh (virtuals first).
# maven-central is kept, because it may have existed before the demo.
# Set DELETE_MAVEN_CENTRAL=1 to delete it too.
# Requires ART_URL, ART_USER, ART_TOKEN.
set -euo pipefail

: "${ART_URL:?Set ART_URL}"
: "${ART_USER:?Set ART_USER}"
: "${ART_TOKEN:?Set ART_TOKEN}"

KEYS=(acmebank_java_repo lightwell-java lightwell-java-remediated lightwell-java-validated)
if [[ "${DELETE_MAVEN_CENTRAL:-}" == "1" ]]; then
  KEYS+=(maven-central)
fi

for key in "${KEYS[@]}"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -u "$ART_USER:$ART_TOKEN" -X DELETE "$ART_URL/artifactory/api/repositories/$key")
  echo "DELETE $key ($code)"
done
