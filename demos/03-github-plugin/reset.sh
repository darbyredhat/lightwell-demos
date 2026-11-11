#!/usr/bin/env bash
# Puts the Demo 3 app repo back to its starting state (before and after each run):
# closes open PRs and deletes their branches, moves main back to the demo-start tag
# (undoing a merged PR without revert commits), and reruns badge sync so the badge shows 5 again.
#
# Usage: demos/03-github-plugin/reset.sh OWNER
# Requires: gh (logged in as OWNER).
set -euo pipefail

OWNER="${1:?Usage: $0 OWNER (your GitHub user or org)}"
APP_REPO="$OWNER/lightwell-demo-payments-service"

for pr in $(gh pr list -R "$APP_REPO" --state open --json number --jq '.[].number'); do
  gh pr close "$pr" -R "$APP_REPO" --delete-branch >/dev/null
  echo "OK    closed PR #$pr"
done

if gh api "repos/$APP_REPO/git/ref/heads/lightwell/remediations" >/dev/null 2>&1; then
  gh api -X DELETE "repos/$APP_REPO/git/refs/heads/lightwell/remediations" >/dev/null
  echo "OK    deleted branch lightwell/remediations"
fi

START_SHA=$(gh api "repos/$APP_REPO/git/ref/tags/demo-start" --jq .object.sha)
MAIN_SHA=$(gh api "repos/$APP_REPO/git/ref/heads/main" --jq .object.sha)
if [[ "$MAIN_SHA" == "$START_SHA" ]]; then
  echo "SKIP  main already at demo-start"
else
  gh api -X PATCH "repos/$APP_REPO/git/refs/heads/main" -f sha="$START_SHA" -F force=true >/dev/null
  echo "OK    main moved back to demo-start (${START_SHA:0:7})"
fi

gh workflow run lightwell-badge-sync.yml -R "$APP_REPO" >/dev/null
echo "OK    badge sync started; the badge shows 5 again about 1 minute after it finishes (hard refresh)"
