# Demo 2 setup (once per presenter)

You need a JFrog Platform instance with Artifactory and Xray (a JFrog cloud trial works) and an admin login. No Lightwell credentials are needed for the public demo feeds. Run every command from the repo root.

## 1. Tools and login

- Java 17, Maven, Python 3.10 or later, `curl` (see [docs/setup.md](../../docs/setup.md)).
- Set your JFrog login in the terminal. Keep it in your shell; don't save it in a file in this repo:
  ```sh
  export ART_URL=https://<your-instance>.jfrog.io
  export ART_USER=<your JFrog user>
  read -rs ART_TOKEN && export ART_TOKEN     # paste an access token; nothing is echoed
  ```
- Install the Xray sync tool: see [tools/lightwell-xray-sync](../../tools/lightwell-xray-sync/README.md).

## 2. One-time setup on your instance

| Step | Command or action | Result |
|---|---|---|
| 1. Repositories | `demos/02-artifactory-xray/setup-repos.sh` | Creates `lightwell-java-remediated`, `lightwell-java-validated`, `lightwell-java`, `acmebank_java_repo`. Reuses an existing `maven-central` unchanged, or creates it |
| 2. Xray policy, Lightwell OSV, cache | `demos/02-artifactory-xray/setup-xray.sh` | Policy `lightwell-demo-security`; Lightwell Custom Issues; woodstox `6.0.3` and `6.0.3.rhlw-00001` cached through `acmebank_java_repo` |
| 3. Watch | If step 2 printed `WARN watch ... (400)`: Xray > Watches & Policies > New Watch: `lightwell-demo-watch`, Add Repositories (the two Lightwell remotes and `maven-central`), Manage Policies: `lightwell-demo-security`, Create | Active watch. On some instances the watch API returns 400 "repository doesn't exist"; the UI works |
| 4. Ignore rule | `demos/02-artifactory-xray/add-ignore-rule.sh` | Ignores JFrog's `XRAY-255585` on `woodstox-core 6.0.3.rhlw-00001`, citing the Lightwell advisory |
| 5. Apply watch to existing content | `demos/02-artifactory-xray/apply-watch.sh` | `{"info":"History Scan is in progress"}`. Violations for already-cached JARs appear within a few minutes |

All scripts are safe to rerun: they skip or update what already exists.

**Production feeds:** `MODE=prod demos/02-artifactory-xray/setup-repos.sh` points the remotes at the production Lightwell feeds, with the Lightwell service account in `LW_USER` and `TOKEN`.

### Why the ignore rule is needed

JFrog's vulnerability data matches by version number. It reads `woodstox-core 6.0.3.rhlw-00001` as below the upstream fix (6.4.0), so JFrog's issue `XRAY-255585` (CVE-2022-40152) flags the Lightwell build even though Red Hat backported the fix. Loading Red Hat's Lightwell advisory (`x_RHLW-CVE-2022-40152-6.0.3`) adds Red Hat's view to Xray, but a Custom Issue can't override JFrog's own entry. The ignore rule records the decision once, with Red Hat's advisory as the evidence.

The ignore rule suppresses the **policy violation**. The JAR's **Security Issues** list still shows JFrog's `XRAY-255585`. Show the violations view for the "clean" result.

## 3. Dry run

```sh
demos/02-artifactory-xray/preflight.sh
```

Expect all `OK`. Then rehearse once with [README.md](README.md), and run its Reset command.

## Troubleshooting setup

| Symptom | Fix |
|---|---|
| Setup script lists a name as taken | A repository with that name already exists. `maven-central` is reused automatically; for others, check who owns it before changing anything |
| `WARN watch ... (400) repository ... doesn't exist` | Create the watch in the UI (step 3). New repositories can also take a few minutes to appear in Xray; rerunning the script retries |
| `lightwell-xray-sync not found` | Install it (see [tools/lightwell-xray-sync](../../tools/lightwell-xray-sync/README.md)), or set `SYNC_TOOL` to its path |

## Teardown (only when retiring the demo)

Don't run this between practice runs: it deletes the setup, which then has to be redone.

```sh
demos/02-artifactory-xray/teardown.sh
```

This deletes the four Lightwell repositories and keeps `maven-central` (set `DELETE_MAVEN_CENTRAL=1` to delete it too, if you created it for the demo).

In Xray > Watches & Policies, delete the watch `lightwell-demo-watch` (Watches tab), the policy `lightwell-demo-security` (Policies tab), and the ignore rule (Ignore Rules tab > rule > Delete Rule). The Lightwell Custom Issues can stay; rerunning the sync updates them.
