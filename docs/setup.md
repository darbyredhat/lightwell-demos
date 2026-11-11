# Setup

Tools each demo needs. Each demo's own `setup.md` covers its one-time steps.

| Tool | Version | Demos | Install (macOS) |
|---|---|---|---|
| Git | any recent | all | `xcode-select --install` |
| Python | 3.10 or later | 1, 2 | `brew install python` |
| cosign | 2.x | 1 | `brew install cosign` |
| curl | any | 1, 2 | preinstalled |
| Java (JDK) | 17 | 2 | `brew install openjdk@17` |
| Maven | 3.9 | 2 | `brew install maven` |
| GitHub CLI (`gh`) | 2.x | 3 | `brew install gh` |
| Node.js | 18 or later | only to re-render slides | `brew install node` |

## Accounts

| Demo | Needs |
|---|---|
| 1 | A Red Hat login for the Lightwell console pages |
| 2 | A JFrog Platform instance with Artifactory and Xray (a cloud trial works), admin login |
| 3 | A GitHub account |

## Credentials

Credentials are only ever read from environment variables or prompted for without echo. Keep them in your shell session, not in files in this repo.

| Variable | Used by | What |
|---|---|---|
| `ART_URL` | Demo 2 | Your JFrog instance, for example `https://<your-instance>.jfrog.io` |
| `ART_USER` | Demo 2 | Your JFrog user |
| `ART_TOKEN` | Demo 2 | A JFrog access token (set with `read -rs ART_TOKEN && export ART_TOKEN`) |
| `LW_USER`, `TOKEN` | Demo 2 with `MODE=prod` only | Lightwell registry service account, for the production feeds |

Demo 3's GitHub token goes straight into a repository secret (see [demos/03-github-plugin/setup.md](../demos/03-github-plugin/setup.md)).
