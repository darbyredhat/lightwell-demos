# Demo 1 setup (once per presenter)

No Lightwell or JFrog credentials are needed; everything uses the public demo feeds.

1. Tools (see [docs/setup.md](../../docs/setup.md) for versions):
   - `python3` (3.10 or later), for the plugin's scanner.
   - `cosign`, for provenance verification: `brew install cosign`.
   - `curl`.
2. A Red Hat login for `console.redhat.com`. Open the two Lightwell demo pages once to check access:
   - `https://console.redhat.com/lightwell/demo/java-remediated-demo`
   - `https://console.redhat.com/lightwell/demo/java-validated-demo`
3. Dry run, from the repo root:
   ```sh
   demos/01-lightwell-walkthrough/preflight.sh
   python3 tools/lightwell-github-plugin/lightwell-github/scan_poms.py --root apps/payments-service --catalog tools/lightwell-github-plugin/lightwell-github/catalog.json --out-dir /tmp/lw-scan
   demos/01-lightwell-walkthrough/verify-provenance.sh com/fasterxml/woodstox woodstox-core 6.0.3.rhlw-00001
   ```
   Expect all `OK`, `5 match(es)`, and both `PASS` lines. Then run the Reset command in [README.md](README.md).
4. Optional: a second monitor for the script, and VS Code for the Markdown preview of the scan report.
