# Demo 3 setup (once per presenter)

You need a GitHub account and the GitHub CLI (`gh`). Run every command from the repo root. `OWNER` below is your GitHub user.

## 1. Log in to GitHub CLI

```sh
gh auth login
```

## 2. Create the demo repos

```sh
demos/03-github-plugin/create-demo-repos.sh OWNER
```

This creates two **public** repos under your account (new repos, not forks, so shields.io can read the badge and GitHub never suggests a PR against someone else's repo):

| Repo | Contents |
|---|---|
| `OWNER/lightwell-demo-plugin` | A copy of [tools/lightwell-github-plugin](../../tools/lightwell-github-plugin/) |
| `OWNER/lightwell-demo-payments-service` | A copy of [apps/payments-service](../../apps/payments-service/), tagged `demo-start` |

The script replaces the `OWNER` placeholder in the workflows and README with your user. Pushing the app triggers **Build** and **Lightwell badge sync** once, which publishes the first badge ("4 available").

At the end it asks for the token (step 3). You can paste it then, or press Enter and set it later.

## 3. Create the token and store it as a secret

Create a **fine-grained personal access token** (GitHub > Settings > Developer settings > Fine-grained tokens):
- **Repository access:** only `OWNER/lightwell-demo-payments-service`.
- **Permissions:** Contents: Read and write; Pull requests: Read and write.
- **Expiration:** your choice (for example 30 days). Put a reminder in your calendar.

If you skipped it in step 2, store it now (input is hidden; the token is never written to a file):

```sh
read -rs PAT && printf '%s' "$PAT" | gh secret set LIGHTWELL_REPO_TOKEN -R OWNER/lightwell-demo-plugin && unset PAT
```

## 4. Dry run

```sh
demos/03-github-plugin/preflight.sh OWNER
```

Expect all `OK`. Then rehearse once with [README.md](README.md) (run the plugin, merge the PR, watch the badge), and finish with `reset.sh OWNER`.

## Updating the demo repos

The demo repos are copies. If the plugin or app in this repo changes, delete both repos on GitHub (Settings > Danger Zone) and run `create-demo-repos.sh` again.
