# Lightwell Demos

Demos of [Red Hat Lightwell](https://console.redhat.com/lightwell): open source libraries rebuilt by Red Hat, with security fixes backported to the version you already run, and signed provenance and an SBOM for every build.

All demos use the **public Lightwell demo feeds**, so no Lightwell credentials are needed.

## Demos

| Demo | What it shows | Needs |
|---|---|---|
| [01 Lightwell walkthrough](demos/01-lightwell-walkthrough/) | The catalog and its tiers, coverage of a real app, and verifying a binary with `cosign` | Red Hat login (console pages) |
| [02 Artifactory and Xray](demos/02-artifactory-xray/) | Lightwell as a trusted upstream in JFrog Artifactory; Xray showing the Lightwell fix next to the upstream one | JFrog instance with Xray |
| [03 GitHub plugin](demos/03-github-plugin/) | A GitHub Actions workflow opens a pull request that switches an app to Lightwell builds, with the CVEs fixed | GitHub account |

Each demo is about 15 minutes, for a technical audience. They share one thread: the `payments-service` app and its **Woodstox 6.0.3** (CVE-2022-40152), fixed by the Lightwell build `6.0.3.rhlw-00001`. Present them in order, or on their own.

Each demo folder has the same files:

| File | When |
|---|---|
| `setup.md` | Once per presenter |
| `preflight.sh` | Before every presentation: prints `OK` or `FAIL` for each check |
| `README.md` | The presenter script: checklist, parts with what to show and say, reset, troubleshooting |
| `slides/` | During the demo: open `slides/index.html` for a slideshow of the opening slide (the three questions) and the recap slide (the results) |

## Quick start

```sh
git clone https://github.com/darbyredhat/lightwell-demos.git && cd lightwell-demos
git checkout $(git tag -l 'demo-*' | tail -1)     # latest known-good version
```

Then install the tools in [docs/setup.md](docs/setup.md) and follow the demo's `setup.md`. Run every command from the repo root.

## Layout

```
demos/   one folder per demo (script, setup, preflight, scripts)
apps/    demo applications (payments-service)
tools/   shared tooling (the Lightwell GitHub plugin, the Xray sync tool)
docs/    setup and architecture
```

A new demo is a new `demos/NN-name/` folder plus a row in the table above.

## Credits and license

The demo app, the GitHub plugin, and the Xray sync tool are based on Anurag Saran's work; see [CREDITS.md](CREDITS.md).

This repo has no license.
