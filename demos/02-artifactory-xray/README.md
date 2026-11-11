# Demo 2: Artifactory Integration plus Xray

**First time?** Do [setup.md](setup.md) once. Run every command from the repo root.

- **Length:** about 15 minutes.
- **Audience:** technical.
- **Story:** Lightwell plugs into Artifactory as a trusted upstream. Developers keep using the same company repository, and Maven resolves Lightwell builds through it. Xray, loaded with Red Hat's Lightwell vulnerability data, shows which builds fix which CVEs.
- **Credentials:** your JFrog login only (`ART_URL`, `ART_USER`, `ART_TOKEN`). No Lightwell credentials (public demo feeds).
- **App:** [apps/payments-service](../../apps/payments-service/) (the same app as Demos 1 and 3), built with [settings.xml](settings.xml), whose Maven mirror sends every download through `acmebank_java_repo`.
- **Last verified:** 2026-11-11.

| Part | Time | What the audience sees |
|---|---|---|
| 1. Lightwell as a trusted upstream | 3 min | Remotes, virtuals, and their order in Artifactory |
| 2. The developer view | 5 min | payments-service builds through `acmebank_java_repo`; one property switches Woodstox to the Lightwell build |
| 3. Xray with Lightwell data | 6 min | Woodstox 6.0.3 (validated) flagged, with the Lightwell fix suggested; the Lightwell build has no violations |
| 4. Wrap-up | 1 min | Business value |

---

## Before the demo

- [ ] Repo on the latest known-good tag: `git fetch --tags && git checkout $(git tag -l 'demo-*' | tail -1)`.
- [ ] JFrog variables set in the demo terminal (`ART_URL`, `ART_USER`, `ART_TOKEN`).
- [ ] Preflight passes (all `OK`):
  ```sh
  demos/02-artifactory-xray/preflight.sh
  ```
- [ ] Maven cache warmed once (the first build downloads all of the app's libraries through Artifactory and takes a few minutes):
  ```sh
  mvn -q -f apps/payments-service/pom.xml -s demos/02-artifactory-xray/settings.xml verify
  mvn -q -f apps/payments-service/pom.xml -s demos/02-artifactory-xray/settings.xml -Dwoodstox.version=6.0.3.rhlw-00001 verify
  ```
- [ ] Browser logged in to your JFrog instance, with tabs open:
  - Administration > Repositories
  - Artifactory > Artifacts
  - Xray > Watch Violations
  - Xray > Watches & Policies > Ignore Rules
- [ ] Watch Violations for `lightwell-demo-watch` shows woodstox `6.0.3` with two violations (JFrog and Lightwell), and none for `6.0.3.rhlw-00001`. Add the Issue ID or Severity column beforehand (table icon) so the rows are distinguishable.

---

## Part 1: Lightwell as a trusted upstream (3 min)

**Show:** Administration > Repositories.

> "Lightwell plugs into Artifactory as remote repositories. Developers don't change anything."

| Repository | Type | Points to |
|---|---|---|
| `lightwell-java-remediated` | Remote | `https://packages.redhat.com/lightwell/public-lightwell-demo/java/remediated/` |
| `lightwell-java-validated` | Remote | `https://packages.redhat.com/lightwell/public-lightwell-demo/java/validated/` |
| `maven-central` | Remote | `https://repo1.maven.org/maven2/` |
| `lightwell-java` | Virtual | remediated, then validated |
| `acmebank_java_repo` | Virtual (the company repository) | `lightwell-java`, then `maven-central` |

**Show:** open `lightwell-java-remediated` > Basic. Point out the URL, List Remote Artifacts (on), and Enable Token Authentication (off).

> "These are the public demo feeds, so no credentials. In production, the Lightwell service account goes here, once, on the remote. It never goes into developers' builds."

**Show:** `acmebank_java_repo` > selected repositories.

> "Order matters. Artifactory checks Lightwell first and falls back to Maven Central, so ordinary dependencies still resolve."

---

## Part 2: The developer view (5 min)

**Show:** [settings.xml](settings.xml) in VS Code: the `<mirror>` block (`mirrorOf *`, URL `.../acmebank_java_repo`).

> "This is the payments service, the same app as in the walkthrough. Its Maven settings have one mirror: every download goes to the company repository, `acmebank_java_repo`. That's the usual way companies route builds through Artifactory, and the app's own pom doesn't change."

**Do (terminal):** build it as it is today.

```sh
mvn -f apps/payments-service/pom.xml -s demos/02-artifactory-xray/settings.xml dependency:tree -Dincludes=com.fasterxml.woodstox
```

Expected: `com.fasterxml.woodstox:woodstox-core:jar:6.0.3` and `BUILD SUCCESS`.

> "The app uses Woodstox 6.0.3, and Artifactory served it from Lightwell's validated tier: rebuilt by Red Hat, but not patched. We'll see what Xray thinks of that in a minute."

**Do:** in `apps/payments-service/pom.xml`, change one line:

```xml
<woodstox.version>6.0.3.rhlw-00001</woodstox.version>
```

**Do (terminal):** build again, with the tests.

```sh
mvn -f apps/payments-service/pom.xml -s demos/02-artifactory-xray/settings.xml dependency:tree -Dincludes=com.fasterxml.woodstox
mvn -f apps/payments-service/pom.xml -s demos/02-artifactory-xray/settings.xml verify | grep -E 'Tests run:|BUILD'
```

Expected: the tree shows `woodstox-core:jar:6.0.3.rhlw-00001`; the build ends with `Tests run: 9, Failures: 0, Errors: 0, Skipped: 0` and `BUILD SUCCESS`. The first command only prints the dependency tree; the second runs the tests.

> "Same version, Lightwell suffix, one line. Artifactory now serves the remediated build, and the app's tests still pass."

**Show:** Artifacts > `lightwell-java-remediated` > `com/fasterxml/woodstox/woodstox-core/6.0.3.rhlw-00001/` (click the folder so the right pane shows its path). Point out the files next to the JAR: `.cyclonedx.json` (SBOM), `.asc` signatures, checksums, `-sources.jar`, `-javadoc.jar`.

> "Lightwell builds come with an SBOM, signatures, and sources, right here in Artifactory."

**Presenter notes:**
- `settings.xml` reads the instance URL and login from `ART_URL`, `ART_USER` and `ART_TOKEN`. Nothing secret is in the file.
- Because the mirror matches `*`, the pom's public Lightwell feeds and Maven Central are also fetched through `acmebank_java_repo`.
- Lines like `... is present in the local repository, but cached from a remote repository ID that is unavailable in current build context` are harmless. The file was cached by an earlier build that used a different repository, so Maven double-checks it through `acmebank_java_repo`.

---

## Part 3: Xray with Lightwell data (6 min)

**Show:** Artifacts > `lightwell-java-validated` > `com/fasterxml/woodstox/woodstox-core/6.0.3/woodstox-core-6.0.3.jar` > Xray tab > Security Issues. Click **Includes Fix Version**.

Expected: two rows for CVE-2022-40152:

| Source | CVSS | Severity | Fix version |
|---|---|---|---|
| JFrog `XRAY-255585` (marked "Enriched by JFrog") | 7.5 | High | `5.4.0, 6.4.0` |
| Lightwell `x_RHLW-CVE-2022-40152-6.0.3` | 6.5 | Medium | `6.0.3.rhlw-00001` |

**Presenter notes:**
- Two scores for one CVE (7.5 vs 6.5): JFrog and Red Hat each score it in their own data.
- The **Contextual Analysis** column ("Not Applicable") and the **Scan for Contextual Analysis** button belong to JFrog's separately licensed Advanced Security feature. Not part of the Lightwell story; if asked, say so and move on.

> "This is the Woodstox the app started with. Validated means rebuilt and verifiable, not patched, so the CVE is still there. Xray gives two ways to fix it. JFrog's data says upgrade to 6.4.0. Red Hat's Lightwell data says use 6.0.3.rhlw-00001: the same version, with the fix backported. That's the change we just made."

> "We load Red Hat's Lightwell advisories into Xray as Custom Issues with a small sync tool. Red Hat publishes them in the standard OSV format."

**Show:** Xray > Watch Violations for `lightwell-demo-watch`.

Expected: **2 violations, both on woodstox `6.0.3`** (JFrog and Lightwell). Woodstox `6.0.3.rhlw-00001` has none.

**Tip:** the default columns (Component, Impacted Artifact, Updated, Policies) make the two rows look identical. Click the table icon under "2 Violations" and add **Issue ID**, **Severity**, or **Type**, or click a row: one is `XRAY-255585` (JFrog, High), the other `x_RHLW-CVE-2022-40152-6.0.3` (Lightwell, Medium).

> "And the Lightwell build the app now uses has no policy violations."

> "One step makes that true. JFrog's database judges by version number and doesn't know Red Hat backported the fix, so it still flags the Lightwell build. Our security team records that decision once, with Red Hat's advisory as evidence. That's this ignore rule."

**Show:** Xray > **Watches & Policies** > **Ignore Rules** tab. Click the rule (notes "Lightwell build: Red Hat advisory x_RHL...") to open its **Details**:

| Field | Value |
|---|---|
| Ignore Vulnerability | `XRAY-255585` |
| Components | version `6.0.3.rhlw-00001` of `gav://com.fasterxml.woodstox:woodstox-core` |
| Notes | "Lightwell build: Red Hat advisory x_RHLW-CVE-2022-40152-6.0.3 records 6.0.3.rhlw-00001 as the fix for this CVE. JFrog data matches by version number and does not know about the Lightwell backport." |

> "The rule says exactly what was decided and why: this one JFrog finding, on this one Lightwell build, with Red Hat's advisory as the evidence."

Close the dialog with **Close** (not **Delete Rule**).

**Presenter note:** if other Lightwell builds were cached on your instance (for example commons-io `2.11.0.rhlw-00001`), the watch may list violations on them too, depending on filters. A validated, unpatched build makes the same point as Woodstox 6.0.3.

---

## Part 4: Wrap-up (1 min)

> "Lightwell slots into Artifactory as an upstream, with credentials in one place. Builds go through the company repository, and a one-line version change picks up the fix. With Red Hat's Lightwell data in Xray, the scanner shows the Lightwell fix next to the upstream one. Next, we'll see a pull request make that change automatically."

---

## Reset (after each run)

Put the app's Woodstox back to `6.0.3`, so the next run (and Demo 1) starts from the "before" state:

```sh
git checkout -- apps/payments-service/pom.xml
```

Leave the repositories and Xray setup in place: the demo needs them. To start again from the top, also clear the terminal (**Cmd+K**), set the browser tabs back to Administration > Repositories, Artifacts (tree collapsed), and Xray > Watch Violations, and open `settings.xml` in VS Code.

To remove everything from your instance when retiring the demo, see Teardown in [setup.md](setup.md).

## Troubleshooting

| Symptom | Fix |
|---|---|
| Preflight `FAIL` on a JAR download | Repositories missing or wrong instance: check `ART_URL`, rerun `setup-repos.sh` (see [setup.md](setup.md)) |
| Watch Violations shows 0 | Watch created after the JARs were scanned: run `demos/02-artifactory-xray/apply-watch.sh`, wait a few minutes |
| Lightwell JAR still lists `XRAY-255585` under Security Issues | Ignore rules suppress violations, not scan issues. Show Watch Violations for the clean result |
| Maven error mentions `${env.ART_URL}` or 401 | JFrog variables not set in this terminal: set `ART_URL`, `ART_USER`, `ART_TOKEN` |
| `The specified user settings file does not exist` | Run from the repo root |
| The first build shows `6.0.3.rhlw-00001` instead of `6.0.3` | `pom.xml` not reset from the last run: run the Reset command |
| `Could not find artifact ... in acmebank_java_repo` | `acmebank_java_repo` missing or its members wrong: rerun `setup-repos.sh` |
