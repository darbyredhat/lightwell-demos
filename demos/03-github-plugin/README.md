# Demo 3: CI/CD Integration with the Lightwell GitHub Plugin

**First time?** Do [setup.md](setup.md) once. Run every command from the repo root. `OWNER` below is your GitHub user.

- **Length:** about 15 minutes.
- **Audience:** technical.
- **Story:** A GitHub Actions workflow scans an app for libraries Lightwell covers and opens a pull request that switches them to Lightwell builds, with the CVEs each one fixes. The app's CI builds and tests the Lightwell versions; a developer reviews and merges.
- **Credentials:** a GitHub fine-grained token, stored as a repository secret. No Lightwell credentials (public demo feeds).
- **Repos** (created once by `create-demo-repos.sh` from this repo's folders):

| Repo | From | Role |
|---|---|---|
| `OWNER/lightwell-demo-plugin` | [tools/lightwell-github-plugin](../../tools/lightwell-github-plugin/) | The plugin: workflow **Lightwell Remediate**, scanner, catalog |
| `OWNER/lightwell-demo-payments-service` | [apps/payments-service](../../apps/payments-service/) | The target app: workflows **Build** and **Lightwell badge sync** |

- **Last verified:** 2026-11-11.

| Part | Time | What the audience sees |
|---|---|---|
| 1. The setup | 3 min | Plugin repo, target app, one secret |
| 2. Run the plugin | 4 min | Actions run: scan, CVE report, PR opened |
| 3. The pull request | 5 min | CVE table, 5-line pom diff, CI builds the Lightwell versions and passes |
| 4. Merge and badge | 2 min | Merge; badge sync updates the count |
| 5. Wrap-up | 1 min | Business value |

---

## Before the demo

- [ ] Reset done and preflight passes (all `OK`):
  ```sh
  demos/03-github-plugin/reset.sh OWNER
  demos/03-github-plugin/preflight.sh OWNER
  ```
- [ ] Badge on the app's home page shows **5 available** (hard refresh, **Cmd+Shift+R**, about 1 minute after the reset).
- [ ] Browser tabs open:
  - `https://github.com/OWNER/lightwell-demo-plugin/actions`
  - `https://github.com/OWNER/lightwell-demo-payments-service` (README with the badge)
  - `https://github.com/OWNER/lightwell-demo-payments-service/pulls`
- [ ] Optional dry run the day before (Actions > Lightwell Remediate > Run workflow > dry_run checked): expect success, "Matches: 5", no PR.

---

## Part 1: The setup (3 min)

**Show:** the opening slide: open [slides/index.html](slides/index.html) in a browser and press F for full screen. Leave it up for about 30 seconds: the three questions this demo answers, and the Woodstox thread.

> "In Demo 2, a developer changed one line by hand to pick up the Woodstox fix. Now let's have a workflow find every fix for the app and propose them as a pull request."

**Show:** the plugin repo: `.github/workflows/lightwell-remediate.yml`.

> "The plugin is a GitHub Actions workflow in its own repo. It holds a catalog of Lightwell builds and a scanner. It opens pull requests from there; nothing in the app's code changes to make that work."

**Show:** `lightwell-github/catalog.json`: the `repositories` section (the two public Lightwell feeds), then the Woodstox entry in `remediations`:

```json
{
  "groupId": "com.fasterxml.woodstox",
  "artifactId": "woodstox-core",
  "fromVersion": "6.0.3",
  "toVersion": "6.0.3.rhlw-00001",
  "tier": "remediated",
  "summary": "Lightwell remediated rebuild of woodstox-core 6.0.3"
}
```

> "The catalog is the plugin's list of Lightwell builds: if your app uses this version, here's the Lightwell build to switch to. The scanner matches it against your poms."

**How the plugin uses it:**

| Step | What happens |
|---|---|
| Scan | `scan_poms.py` compares each dependency in the app's `pom.xml` files with the catalog |
| Exact match (library and `fromVersion`) | Proposes `toVersion`, and looks up the CVEs that build fixes in Red Hat's Lightwell OSV data (the PR's CVE and CVSS table) |
| Library matches, other version | Reported as "serviced at a different version", informational only. None for payments-service with this catalog |
| Apply | `apply_bumps.py` writes the `toVersion` values into the pom; that becomes the PR |

**Presenter note:** the catalog has 8 entries; 5 match payments-service (org.json, woodstox-core, json-path, commons-io, jackson-databind). It lists only builds verified to build on the public feed; httpclient 4.5.12 and spring-core 5.3.18 were removed because their Lightwell builds are missing dependencies there.

**Show:** Settings > Secrets and variables > Actions: `LIGHTWELL_REPO_TOKEN`.

> "One secret: a fine-grained token that can push a branch and open pull requests on the target app. That's the only access it needs."

**Show:** the app repo: `pom.xml` properties (spring-core 5.3.18, jackson 2.13.4, commons-io 2.11.0, json-path 2.7.0, woodstox 6.0.3, ...).

> "A normal Maven app: no Lightwell code in the application. The one Lightwell piece is an optional workflow, `lightwell-badge-sync.yml`, that refreshes the README badge when the pom changes."

**Presenter note:** `lightwell-badge-sync.yml` checks out the plugin repo, reruns the scan on `main`, and publishes `lightwell-badge.json` on the `lightwell/badge` branch. It's optional: remediation PRs work without it, and the app's CI (`build.yml`) is plain Maven.

---

## Part 2: Run the plugin (4 min)

**Do:** plugin repo > Actions > **Lightwell Remediate** > **Run workflow** > target `OWNER/lightwell-demo-payments-service`, dry_run **unchecked** > Run.

> "In production this runs on a schedule across all your apps. Here we start it by hand."

**Show:** the run (about 1 minute): Select target repos > Remediate. Open the job summary.

Expected: "Available library updates: 5", the Lightwell report (bumps with CVEs and CVSS), and "Opened or updated on OWNER/lightwell-demo-payments-service: <PR URL>".

---

## Part 3: The pull request (5 min)

**Show:** the PR on the app repo (label `lightwell`, branch `lightwell/remediations`). Open it from the job summary link or the app's **Pull requests** tab.

> "The plugin opened a normal pull request. It lists every bump with the CVEs it fixes, straight from Red Hat's Lightwell advisories."

| Dependency | From | To | CVEs fixed |
|---|---|---|---|
| org.json | 20220320 | 20220320.0.0.rhlw-00003 | CVE-2022-45688 (7.5 High), CVE-2023-5072 (7.5 High) |
| woodstox-core | 6.0.3 | 6.0.3.rhlw-00001 | CVE-2022-40152 (6.5 Medium) |
| json-path | 2.7.0 | 2.7.0.rhlw-00001 | CVE-2023-51074 (5.3 Medium) |
| commons-io | 2.11.0 | 2.11.0.rhlw-00001 | validated rebuild |
| jackson-databind | 2.13.4 | 2.13.4.rhlw-00001 | validated rebuild |

**Show:** Files changed: five lines in `pom.xml`.

> "Same versions, just the Lightwell suffix. No code changes."

**Show:** Checks: **Build / mvn verify** passing.

> "The app's own CI builds and tests the Lightwell versions in this PR. Green means the drop-ins work for this app."

**Presenter note:** org.json: the app's `20220320` and Lightwell's `20220320.0.0` are the same upstream release; Lightwell writes the version with `.0.0`.

---

## Part 4: Merge and badge (2 min)

**Show:** the app README badge: "Lightwell library updates: 5 available".

**Do:** merge the PR.

> "After merge, the app's badge sync workflow rescans and updates the count automatically."

**Show:** Actions > **Lightwell badge sync** running on `main` (about 20 seconds). Then go to the app's home page, **wait about 1 minute**, and do a **hard refresh** (**Cmd+Shift+R**). A normal refresh keeps showing the old count, because shields.io and the browser cache the badge.

> While waiting: "The badge is an image served by shields.io, so it takes about a minute to catch up." Use the minute to recap the PR.

Expected: the badge goes from **5 available** to **0 available**. Actions shows **Build** and **Lightwell badge sync** both succeeded on `main` after the merge.

> "Five down to zero. Every Lightwell update for this app is applied, CI proved it builds, and a person approved the merge."

To check from the terminal:

```sh
gh run list -R OWNER/lightwell-demo-payments-service --branch main --limit 2
gh api "repos/OWNER/lightwell-demo-payments-service/contents/lightwell-badge.json?ref=lightwell/badge" --jq .content | base64 -d | grep message
```

---

## Part 5: Wrap-up (1 min)

**Show:** the recap slide: press the right arrow in the slideshow (or open [slides/index.html#2](slides/index.html#2)): the plugin's three pieces, the pull request, the badge going from 5 to 0, and the three takeaways along the bottom.

> "Lightwell plugs into the workflow your developers already use: pull requests and CI. The scan finds what's covered, the PR shows the CVEs fixed, CI proves it builds, and a person decides to merge."

---

## Reset (before and after each run)

```sh
demos/03-github-plugin/reset.sh OWNER
```

It closes open PRs and deletes their branch, moves the app's `main` back to the `demo-start` tag (undoing a merged PR without revert commits), and reruns badge sync. Wait about 1 minute after badge sync finishes, then hard refresh (**Cmd+Shift+R**) to see "5 available".

## Troubleshooting

| Symptom | Fix |
|---|---|
| Run fails at "Require LIGHTWELL_REPO_TOKEN" | Secret missing or expired; set it again (see [setup.md](setup.md)) |
| 403 or 404 checking out the app | Token not granted on `OWNER/lightwell-demo-payments-service`, or wrong target |
| No PR, "No Lightwell remediations available" | The app's `main` already has the Lightwell versions (a PR was merged); run `reset.sh` |
| PR updated instead of new | An open PR from `lightwell/remediations` exists; run `reset.sh` first |
| Build check fails on the PR | A bumped Lightwell build doesn't resolve on the public feed; check the catalog |
| Badge doesn't change | Shields.io and the browser cache it. Wait about 1 minute after badge sync finishes, then hard refresh (**Cmd+Shift+R**). If it still doesn't change, check badge sync succeeded, or run it manually |
| Preflight `FAIL main at demo-start` right after a reset | Run `reset.sh` again; if it repeats, check the app repo has no branch protection on `main` |
