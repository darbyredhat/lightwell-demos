# Demo 1: Lightwell Walkthrough

**First time?** Do [setup.md](setup.md) once. Run every command from the repo root.

- **Length:** about 15 minutes.
- **Audience:** technical.
- **Story:** Every Java app ships open source libraries with known CVEs, and the usual fix is an upgrade. Lightwell fixes the exact version you already run. We look at what's in the catalog, how much of a real app it covers, and how every binary can be verified as built by Red Hat.
- **Thread through all three demos:** the `payments-service` app and its **Woodstox 6.0.3** (CVE-2022-40152). Demo 1 introduces it; Demo 2 serves the fix through Artifactory; Demo 3 applies it with a pull request.
- **Credentials:** none. Everything uses the public demo feeds.
- **Code used:** [apps/payments-service](../../apps/payments-service/) and the scanner in [tools/lightwell-github-plugin](../../tools/lightwell-github-plugin/) (the same ones Demo 3 uses, so the numbers match).
- **Last verified:** 2026-11-11.
- **Screen layout:** share monitor 1 (terminal, VS Code, browser); keep this script on monitor 2.

| Part | Time | What the audience sees |
|---|---|---|
| Opening | 1 min | The problem: CVEs, upgrades, regression testing |
| 1. The curated repository | 3 min | Tiers and version suffixes, in the console |
| 2. Coverage of a real app | 5 min | The plugin scans `payments-service`: 4 drop-in Lightwell builds, with the CVEs they fix |
| 3. Hardened binaries | 5 min | SBOM, signed provenance, signatures; `cosign` verifies, the tamper test fails |
| 4. Wrap-up | 1 min | Three takeaways, then the hand-off to Demo 2 |

---

## Before the demo

- [ ] Repo on the latest known-good tag: `git fetch --tags && git checkout $(git tag -l 'demo-*' | tail -1)`.
- [ ] Leftovers from a practice run cleared (the Reset command):
  ```sh
  rm -rf /tmp/lw-scan; find /tmp -maxdepth 1 -name 'lw-provenance.*' -exec rm -rf {} +
  ```
- [ ] Preflight passes (all `OK`):
  ```sh
  demos/01-lightwell-walkthrough/preflight.sh
  ```
- [ ] Browser logged in to `console.redhat.com`, with these tabs open:
  - `https://console.redhat.com/lightwell/demo/java-remediated-demo`
  - `https://console.redhat.com/lightwell/demo/java-validated-demo`
- [ ] Decide 2–3 things to point at on the console pages (see Part 1).
- [ ] **Backup terminal tab:** run the Part 2 scan and the Part 3 provenance command once in a second terminal tab and leave the output there. If the network is slow live, switch to that tab and keep going.
- [ ] Screen polish: terminal font about 16, close notifications and unrelated tabs, and be ready to zoom VS Code's Markdown preview (**Cmd+=**).

**Console pages:** they need a Red Hat login and display a sensitivity notice. Show them live, but don't copy their data into notes or docs.

---

## Opening (1 min)

**Show:** the opening slide: open [slides/index.html](slides/index.html) in a browser and press F for full screen. It shows the three questions the demo answers, without the results, so the live scan and tamper test keep their surprise. To change a slide, edit its `.html` file in [slides/](slides/) and re-render the PNG (command in [slides/README.md](slides/README.md)).

> "Every Java app ships open source libraries, and many have known CVEs. The usual fix is an upgrade: a new version, regression testing, sometimes breaking changes, across every app that uses it. Lightwell takes a different approach: Red Hat fixes the exact version you already run."

> "In the next few minutes: what's in Lightwell, how much of a real app it covers, and how you can verify every binary."

---

## Part 1: The curated repository (3 min)

**Show:** the console demo pages (`java-remediated-demo`, then `java-validated-demo`).

What to point at (pick 2–3 and rehearse them; adapt to what the pages show):
- How to find a library, for example `woodstox-core`.
- Where the page shows which tier a build belongs to (validated or remediated).
- A version with the `.rhlw` suffix next to the plain upstream version.

> "Lightwell gives you open source libraries rebuilt by Red Hat in a secure pipeline. Every build is signed and comes with an SBOM and SLSA Level 3 provenance."

Explain the tiers:

| Tier | What it holds | Version example |
|---|---|---|
| Validated | Securely rebuilt upstream versions, not patched | `6.0.3` |
| Remediated | The same versions with security fixes backported | `6.0.3.rhlw-00001` |
| Predisclosure | Fixes for vulnerabilities not yet public (production only) | `6.0.3.rhlw-00001-n0001` |

> "`.rhlw-00001` means the first Lightwell build with security fixes for that exact upstream version. Higher numbers add more fixes."

**Optional (if asked "where does this come from?"):** show the same library in both public tiers, straight from the feed.

```sh
curl -s https://packages.redhat.com/lightwell/public-lightwell-demo/java/validated/com/fasterxml/woodstox/woodstox-core/maven-metadata.xml | grep -o '<version>[^<]*</version>'
curl -s https://packages.redhat.com/lightwell/public-lightwell-demo/java/remediated/com/fasterxml/woodstox/woodstox-core/maven-metadata.xml | grep -o '<version>[^<]*</version>'
```

Expected: validated `6.0.3`; remediated `6.0.3.rhlw-00001`.

**Presenter note:** in the public demo feed, some validated builds also carry a `.rhlw` suffix (for example commons-io `2.11.0.rhlw-00001`). In production, validated builds use plain upstream versions. If asked, say the public feed is a demo snapshot.

---

## Part 2: Coverage of a real app (5 min)

> "So how much of a real application does Lightwell cover? Here's a payments service with typical dependencies: Spring, Jackson, Commons IO, JSON libraries, Woodstox."

**Show:** `apps/payments-service/pom.xml` (the `<properties>` block with the versions). Point at `<woodstox.version>6.0.3</woodstox.version>`.

> "Keep an eye on Woodstox 6.0.3. It has a known CVE: a malicious XML file can crash it. We'll follow it through all three demos."

**Do (terminal):** run Anurag's plugin scanner against it.

```sh
python3 tools/lightwell-github-plugin/lightwell-github/scan_poms.py --root apps/payments-service --catalog tools/lightwell-github-plugin/lightwell-github/catalog.json --out-dir /tmp/lw-scan
code /tmp/lw-scan/report.md
```

Expected: `Wrote /private/tmp/lw-scan/matches.json (5 match(es))`: 4 drop-ins plus json-path, which is serviced at a different version.

**Show:** `report.md` in VS Code's Markdown preview (**Cmd+Shift+V**, zoom with **Cmd+=**). Walk through the "Proposed bumps" table:

| Dependency | You run | Lightwell build | CVEs fixed |
|---|---|---|---|
| org.json | 20220320 | 20220320.0.0.rhlw-00003 | CVE-2022-45688 (7.5 High), CVE-2023-5072 (7.5 High) |
| **woodstox-core** | **6.0.3** | **6.0.3.rhlw-00001** | **CVE-2022-40152 (6.5 Medium)** |
| commons-io | 2.11.0 | 2.11.0.rhlw-00001 | validated rebuild |
| jackson-databind | 2.13.4 | 2.13.4.rhlw-00001 | validated rebuild |

The table also lists json-path 2.7.0 as **Serviced at a different version** (`2.8.0.rhlw-00001`, CVE-2023-51074): Lightwell covers it at 2.8.0, which is a real upgrade, so it isn't proposed as a drop-in.

> "Four of the app's 15 dependencies have drop-ins: same version, just a Lightwell suffix, no code change. Two of them fix three known CVEs, two of those High. The CVE details come straight from Red Hat's Lightwell advisories."

**Show:** the "Proposed pom diff" section.

> "This is exactly the change the CI/CD integration proposes as a pull request. We'll see that in Demo 3."

**Ask the audience:**

> "Which libraries in your own stack worry you most?"

Note the answers; they're useful for follow-up.

**Presenter note:** the plugin's catalog in this repo lists only Lightwell builds that resolve and build on the public demo feed. The original catalog (generated from the feeds) also matches spring-core and httpclient, but on the public feed those builds are missing dependencies (`spring-jcl`, the httpclient parent POM). If asked, say the catalog lists what's verified to build.

---

## Part 3: Hardened binaries (5 min)

> "Supply-chain attacks swap or tamper with binaries. So how would you know the JAR you downloaded is really the one Red Hat built?"

> "Every Lightwell binary ships with evidence: an SBOM, signed build provenance, and signatures. Anyone can verify it. Let's check the Woodstox build."

**Do (terminal, repo root):**

```sh
demos/01-lightwell-walkthrough/verify-provenance.sh com/fasterxml/woodstox woodstox-core 6.0.3.rhlw-00001
```

**Presenter note: the script tampers on purpose.** After verifying the real JAR, it makes a **copy** (`tampered.jar`), appends one byte to the copy, and verifies that. The copy is supposed to fail, so the red cosign error line is the expected result. The real JAR, Red Hat's servers, and Artifactory are never changed; everything happens in a temporary folder (`/tmp/lw-provenance.XXXXXX`).

Expected output, and what to say as each step appears:

| Step | Result | Say |
|---|---|---|
| Download | JAR (1,598,134 bytes), `.provenance.sigstore.json`, `.cyclonedx.json`, `.jar.asc`, all 200 | "The JAR, its signed provenance, its SBOM, and a signature." |
| Verify provenance | `PASS: the JAR matches Red Hat's signed provenance` (cosign: `Verified OK`) | "Verified OK means Red Hat's provenance key signed a statement about exactly this JAR." |
| Tamper test | `PASS: the tampered copy is rejected, as expected` (cosign: `... digests do not match digests in statement`). The cosign error line is the expected result | "Change one byte, and verification fails. That's how you know the binary you run is the one Red Hat built." |
| SBOM | CycloneDX 1.6, supplier Red Hat, 904 components | "The SBOM lists all 904 components that went into building it, so your security team knows exactly what's inside." |
| Provenance | SLSA v1, builder `project-ncl/pnc` (Red Hat's build system) | "Built in Red Hat's build system, with SLSA provenance." |

**Optional:** show Red Hat's OSV advisory for this build.

```sh
curl -s https://packages.redhat.com/api/pulp-content/public-lightwell-demo/osv/java/remediated/x_RHLW-CVE-2022-40152-6.0.3.json | grep -o '"fixed"[^}]*'
```

Expected: `"fixed": "6.0.3.rhlw-00001"`.

**Presenter note:** the provenance lists internal source repository addresses. They're in the public file, but don't zoom in on them.

---

## Part 4: Wrap-up (1 min)

**Show:** the recap slide: press the right arrow in the slideshow (or open [slides/index.html#2](slides/index.html#2)): the results of each part, the Woodstox change, and the three takeaways along the bottom.

> "Three takeaways:"
>
> - **Fix without upgrading:** the same version, with the security fix backported.
> - **Know what you're running:** coverage of your actual app, with the CVEs each build fixes.
> - **Trust, but verify:** signed provenance and an SBOM that anyone can check.

> "Next: how this reaches your developers through Artifactory, without them changing how they work. And we'll see that Woodstox 6.0.3 again."

---

## Likely questions (short answers)

| Question | Answer |
|---|---|
| Validated vs remediated? | Validated: rebuilt and verifiable, not patched. Remediated: the same version, with security fixes backported |
| Why the public feed? | A demo snapshot that needs no credentials. Production adds predisclosure and the full catalog |
| What's predisclosure? | Fixes before a CVE is public. Production only, so it's greyed out on the recap slide |
| Why only 4 of 15? | The catalog lists builds verified to build on the public feed. Spring and HttpClient have Lightwell builds, but they're missing dependencies there. json-path is covered at 2.8.0, not the app's 2.7.0. Production covers more |
| How do I trust the JAR? | `cosign` checks Red Hat's signed SLSA provenance against the JAR's digest |

---

## Reset

```sh
rm -rf /tmp/lw-scan; find /tmp -maxdepth 1 -name 'lw-provenance.*' -exec rm -rf {} +
```

(zsh stops a plain `rm -rf /tmp/lw-provenance.*` with "no matches found" when nothing matches; `find` avoids that.)

## Troubleshooting

| Symptom | Fix |
|---|---|
| Scan shows `0 match(es)` | `apps/payments-service/pom.xml` has Lightwell versions (left over from Demo 2 practice). Run `git checkout -- apps/payments-service/pom.xml` |
| Scan shows a different number than 5 | The catalog changed; check `git log -1 -- tools/lightwell-github-plugin/lightwell-github/catalog.json`, or check out the latest `demo-*` tag |
| `can't open file ... scan_poms.py` or `Catalog not found` | Run from the repo root |
| `cosign is required` | `brew install cosign` (see [setup.md](setup.md)) |
| Downloads return 403 | Wrong `FEED`; the public demo feed needs no credentials |
| Network slow or down | Switch to the backup terminal tab with the pre-run output |
