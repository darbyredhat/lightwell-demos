#!/usr/bin/env bash
# Creates the two Demo 3 repos under your GitHub account (run once):
#   OWNER/lightwell-demo-plugin            the plugin (from tools/lightwell-github-plugin)
#   OWNER/lightwell-demo-payments-service  the app    (from apps/payments-service), tagged demo-start
# Both are public, new repos (not forks), so shields.io can read the badge.
# Then stores LIGHTWELL_REPO_TOKEN on the plugin repo; the token is read without echo and never written to a file.
#
# Usage: demos/03-github-plugin/create-demo-repos.sh OWNER
# Requires: gh (logged in as OWNER), git.
set -euo pipefail

OWNER="${1:?Usage: $0 OWNER (your GitHub user or org)}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_REPO="$OWNER/lightwell-demo-plugin"
APP_REPO="$OWNER/lightwell-demo-payments-service"

gh auth status >/dev/null 2>&1 || { echo "Log in first: gh auth login" >&2; exit 1; }
for repo in "$PLUGIN_REPO" "$APP_REPO"; do
  if gh repo view "$repo" >/dev/null 2>&1; then
    echo "$repo already exists. To start over, use reset.sh; to recreate, delete it on GitHub first." >&2
    exit 1
  fi
done

WORK="$(mktemp -d /tmp/lw-demo-repos.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# Copies a folder from this repo, replaces the OWNER placeholder, commits, and creates the GitHub repo.
publish() {
  local source="$1" repo="$2" description="$3" dir
  dir="$WORK/$(basename "$repo")"
  mkdir -p "$dir"
  (cd "$REPO_ROOT/$source" && tar -cf - --exclude target --exclude __pycache__ .) | (cd "$dir" && tar -xf -)
  { grep -rlIE 'OWNER/lightwell-demo-|OWNER%2Flightwell-demo-' "$dir" || true; } | while read -r file; do
    sed -i.bak -e "s|OWNER/lightwell-demo-|$OWNER/lightwell-demo-|g" -e "s|OWNER%2Flightwell-demo-|$OWNER%2Flightwell-demo-|g" "$file"
    rm -f "$file.bak"
  done
  git -C "$dir" init -q -b main
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "Initial demo copy from lightwell-demos"
  gh repo create "$repo" --public --description "$description" --source "$dir" --push >/dev/null
  echo "OK    created https://github.com/$repo"
}

publish tools/lightwell-github-plugin "$PLUGIN_REPO" "Lightwell GitHub plugin (demo copy from lightwell-demos)"
publish apps/payments-service "$APP_REPO" "Demo app for the Lightwell GitHub plugin (from lightwell-demos)"

git -C "$WORK/lightwell-demo-payments-service" tag demo-start
git -C "$WORK/lightwell-demo-payments-service" push -q origin demo-start
echo "OK    tagged $APP_REPO main as demo-start"

echo
echo "Paste a fine-grained GitHub token with Contents and Pull requests (read and write) on $APP_REPO."
echo "Input is hidden. Press Enter on an empty line to skip and set it later (see setup.md)."
read -rs TOKEN_INPUT
if [[ -n "$TOKEN_INPUT" ]]; then
  printf '%s' "$TOKEN_INPUT" | gh secret set LIGHTWELL_REPO_TOKEN -R "$PLUGIN_REPO"
  echo "OK    secret LIGHTWELL_REPO_TOKEN set on $PLUGIN_REPO"
else
  echo "SKIP  secret not set"
fi
unset TOKEN_INPUT
