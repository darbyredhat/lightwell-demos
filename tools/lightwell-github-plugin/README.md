# Lightwell GitHub plugin

A GitHub Actions workflow that scans an app repo for libraries with Lightwell builds and opens a pull request that switches them, listing the CVEs each build fixes (from Red Hat's Lightwell OSV advisories). Used by [Demo 3](https://github.com/darbyredhat/lightwell-demos/tree/main/demos/03-github-plugin/) and, for its scanner, [Demo 1](https://github.com/darbyredhat/lightwell-demos/tree/main/demos/01-lightwell-walkthrough/).

Originally written by Anurag Saran ([anurag-saran/lightwell-github-plugin-demo](https://github.com/anurag-saran/lightwell-github-plugin-demo)); see [CREDITS.md](https://github.com/darbyredhat/lightwell-demos/blob/main/CREDITS.md) for what changed.

## Contents

| Path | Role |
|---|---|
| `lightwell-github/catalog.json` | Lightwell builds the plugin proposes: `fromVersion` (what you run) to `toVersion` (the Lightwell build), plus the feeds |
| `lightwell-github/scan_poms.py` | Scans `pom.xml` files against the catalog; writes `matches.json` and `report.md` with CVEs and CVSS |
| `lightwell-github/osv_cves.py` | Fetches Lightwell OSV advisories and attaches the CVEs to each match |
| `lightwell-github/apply_bumps.py` | Writes the `toVersion` values into the poms (the pull request's change) |
| `lightwell-github/write_badge.py` | Writes the shields.io badge JSON |
| `lightwell-github/sync_catalog.py` | Rebuilds `catalog.json` from the Lightwell feeds (see the note below) |
| `.github/workflows/lightwell-remediate.yml` | The workflow: scan, badge, pull request on the target repo |
| `tests/` | Unit tests |

**Catalog note:** this copy lists only builds verified to resolve and build on the public demo feeds (8 entries; 5 match payments-service). Running `sync_catalog.py` regenerates it from the feeds and brings back entries that don't build there, such as httpclient `4.5.12` and spring-core `5.3.18`.

## Run the scanner locally

From the repo root:

```sh
python3 tools/lightwell-github-plugin/lightwell-github/scan_poms.py --root apps/payments-service --catalog tools/lightwell-github-plugin/lightwell-github/catalog.json --out-dir /tmp/lw-scan
```

Add `--no-osv` to skip the CVE lookup (no network).

## Tests

```sh
python3 -m unittest discover -s tools/lightwell-github-plugin/tests -v
```
