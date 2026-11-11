#!/usr/bin/env bash
# Read-only checks before presenting Demo 3. Prints OK or FAIL per check; exits 1 if any check fails.
#
# Usage: demos/03-github-plugin/preflight.sh OWNER
set -uo pipefail

OWNER="${1:?Usage: $0 OWNER (your GitHub user or org)}"
PLUGIN_REPO="$OWNER/lightwell-demo-plugin"
APP_REPO="$OWNER/lightwell-demo-payments-service"
FAILED=0

ok()   { echo "OK    $1"; }
fail() { echo "FAIL  $1"; FAILED=1; }

if gh auth status >/dev/null 2>&1; then ok "gh logged in"; else fail "gh logged in (gh auth login)"; exit 1; fi
for repo in "$PLUGIN_REPO" "$APP_REPO"; do
  if gh repo view "$repo" >/dev/null 2>&1; then ok "$repo exists"; else fail "$repo exists (run create-demo-repos.sh)"; fi
done

if gh secret list -R "$PLUGIN_REPO" 2>/dev/null | grep -q '^LIGHTWELL_REPO_TOKEN'; then
  ok "secret LIGHTWELL_REPO_TOKEN on $PLUGIN_REPO"
else
  fail "secret LIGHTWELL_REPO_TOKEN on $PLUGIN_REPO (see setup.md)"
fi

open_prs=$(gh pr list -R "$APP_REPO" --state open --json number --jq 'length' 2>/dev/null || echo "?")
if [[ "$open_prs" == "0" ]]; then ok "no open PRs on $APP_REPO"; else fail "no open PRs on $APP_REPO ($open_prs open; run reset.sh)"; fi

start_sha=$(gh api "repos/$APP_REPO/git/ref/tags/demo-start" --jq .object.sha 2>/dev/null || true)
main_sha=$(gh api "repos/$APP_REPO/git/ref/heads/main" --jq .object.sha 2>/dev/null || true)
if [[ -n "$start_sha" && "$start_sha" == "$main_sha" ]]; then ok "main at demo-start"; else fail "main at demo-start (run reset.sh)"; fi

exit "$FAILED"
