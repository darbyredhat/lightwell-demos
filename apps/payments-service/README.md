# payments-service

[![Lightwell library updates](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2FOWNER%2Flightwell-demo-payments-service%2Flightwell%2Fbadge%2Flightwell-badge.json)](https://github.com/OWNER/lightwell-demo-payments-service/pulls?q=is%3Apr+is%3Aopen+label%3Alightwell)

A small demo Maven app (`com.example.payments`) with typical open source dependencies, used by all three demos. Not a production payments product.

Originally written by Anurag Saran ([anurag-saran/payments-service](https://github.com/anurag-saran/payments-service)); see [CREDITS.md](https://github.com/darbyredhat/lightwell-demos/blob/main/CREDITS.md) for what changed.

## Build

JDK 17 and Maven:

```sh
mvn -B verify
```

`pom.xml` uses community versions (for example `woodstox-core 6.0.3`) and declares the two public Lightwell demo feeds, so the Lightwell builds resolve when a demo switches to them.

## Used by

| Demo | How |
|---|---|
| [01 Lightwell walkthrough](https://github.com/darbyredhat/lightwell-demos/tree/main/demos/01-lightwell-walkthrough/) | The plugin's scanner reads this `pom.xml` |
| [02 Artifactory and Xray](https://github.com/darbyredhat/lightwell-demos/tree/main/demos/02-artifactory-xray/) | Built through Artifactory (a Maven mirror in that demo's `settings.xml`) |
| [03 GitHub plugin](https://github.com/darbyredhat/lightwell-demos/tree/main/demos/03-github-plugin/) | Copied into its own GitHub repo; the plugin opens a pull request on it |

In the Demo 3 repo, `.github/workflows/build.yml` runs `mvn verify` on every push and pull request, and `lightwell-badge-sync.yml` refreshes the badge above after `pom.xml` changes on `main`. `OWNER` in this file and the workflows is replaced by `create-demo-repos.sh`.
