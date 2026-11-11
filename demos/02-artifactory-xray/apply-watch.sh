#!/usr/bin/env bash
# Applies the watch lightwell-demo-watch to artifacts scanned before the watch existed
# (by default, the last 3 days), so their violations appear. Violations show up within a few minutes.
# Requires ART_URL, ART_USER, ART_TOKEN.
set -euo pipefail

: "${ART_URL:?Set ART_URL}"
: "${ART_USER:?Set ART_USER}"
: "${ART_TOKEN:?Set ART_TOKEN}"
WATCH="${WATCH:-lightwell-demo-watch}"
DAYS="${DAYS:-3}"

START=$(python3 -I -c 'import datetime, sys; print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=int(sys.argv[1]))).strftime("%Y-%m-%dT%H:%M:%SZ"))' "$DAYS")
END=$(date -u +%Y-%m-%dT%H:%M:%SZ)

curl -s -u "$ART_USER:$ART_TOKEN" -H 'Content-Type: application/json' -X POST "$ART_URL/xray/api/v1/applyWatch" \
  -d "{\"watch_names\":[\"$WATCH\"],\"date_range\":{\"start_date\":\"$START\",\"end_date\":\"$END\"}}"
echo
