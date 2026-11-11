# Credits

These folders are copies of Anurag Saran's original code, with changes for these demos. Thank you, Anurag.

| Folder | Source | Copied at |
|---|---|---|
| [apps/payments-service](apps/payments-service/) | [anurag-saran/payments-service](https://github.com/anurag-saran/payments-service) | `52be5c2` (2026-10-30) |
| [tools/lightwell-github-plugin](tools/lightwell-github-plugin/) | [anurag-saran/lightwell-github-plugin-demo](https://github.com/anurag-saran/lightwell-github-plugin-demo) | `dfb2ee2` (2026-09-29) |
| [tools/lightwell-xray-sync](tools/lightwell-xray-sync/) | `xray/` in [anurag-saran/lightwell-integrations](https://github.com/anurag-saran/lightwell-integrations) | `1ebe09b` (2026-10-19) |

The repository names and remote settings in [demos/02-artifactory-xray](demos/02-artifactory-xray/) follow `artifactory/README.md` in `lightwell-integrations`.

The original repos have no license file, except that `lightwell-xray-sync`'s `pyproject.toml` declares Apache-2.0. The copies here keep whatever terms apply to the originals.

## Changes

**apps/payments-service**
- `build.yml` runs `mvn -B -q verify` instead of the `ci-community` profile, which pinned the community versions so CI never tested the Lightwell versions in a pull request.
- Badge sync points at the demo plugin repo (`OWNER` placeholder, filled in by `create-demo-repos.sh`).
- Removed folders not used by these demos: `deploy/`, `scripts/`, `.tekton/`, `.upgrade-delta/`, `Dockerfile`, `coverage-map.json`, `pom-demo-trigger.xml`, `settings.xml.template`. New, shorter README.

**tools/lightwell-github-plugin**
- `lightwell-remediate.yml` targets one app repo (`OWNER` placeholder) instead of four, and runs only when started manually (no schedule or push triggers).
- `catalog.json`: maps org.json `20220320` to `20220320.0.0.rhlw-00003` (the same release, so it becomes a drop-in), and removes snakeyaml `1.33.0` (the app runs `1.30`), httpclient `4.5.12` and spring-core `5.3.18` (their Lightwell builds are missing dependencies on the public feed). Result: 8 entries, 5 drop-in matches for payments-service.
- Removed `lightwell-ci.yml` and `samples/`. New, shorter README.

**tools/lightwell-xray-sync**
- Removed `Dockerfile`, `examples/`, `GUIDE.md`, design and gap notes, the `push_osv_to_xray.py` shim and `requirements.txt` (dependencies are in `pyproject.toml`). New, shorter README.
