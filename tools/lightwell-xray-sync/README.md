# lightwell-xray-sync

Loads Red Hat's Lightwell OSV advisories into JFrog Xray as Custom Issues, so Xray shows the Lightwell fix version (for example `6.0.3.rhlw-00001`) next to the upstream fix. Used by [Demo 2](../../demos/02-artifactory-xray/).

Originally written by Anurag Saran as `xray/` in [anurag-saran/lightwell-integrations](https://github.com/anurag-saran/lightwell-integrations) (its `pyproject.toml` declares Apache-2.0); see [CREDITS.md](../../CREDITS.md).

## Install

From the repo root (Python 3.10 or later):

```sh
python3 -m venv tools/lightwell-xray-sync/.venv
tools/lightwell-xray-sync/.venv/bin/pip install -q ./tools/lightwell-xray-sync
```

`demos/02-artifactory-xray/setup-xray.sh` uses this path by default (override with `SYNC_TOOL`).

## Use

The tool reads `JFROG_URL`, `JFROG_TOKEN` (needs **Manage Xray Metadata**), and optionally `JFROG_USER` and `LIGHTWELL_OSV_URL` (defaults to the public demo OSV feed).

```sh
tools/lightwell-xray-sync/.venv/bin/lightwell-xray-sync self-test
tools/lightwell-xray-sync/.venv/bin/lightwell-xray-sync sync --dry-run
tools/lightwell-xray-sync/.venv/bin/lightwell-xray-sync sync -v
tools/lightwell-xray-sync/.venv/bin/lightwell-xray-sync push --input advisory.json
```
