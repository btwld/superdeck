# superdeck_deploy

Deployment tooling for [SuperDeck](https://github.com/btwld/superdeck)
presentations. Ships the built Flutter web app of a deck to a host. This is a
standalone executable, separate from the `superdeck` CLI (which handles
`build` and `setup`).

## Install

```bash
dart pub global activate superdeck_deploy
```

## Usage

Build your deck first with the SuperDeck CLI, then deploy:

```bash
superdeck build
superdeck-deploy github-pages
```

### `github-pages`

Publishes the built web app to a GitHub Pages branch using an isolated git
worktree (your working tree is never touched). It auto-detects `--base-href`
from the `origin` remote, installs a loading `index.html`, writes `.nojekyll`,
and commits/pushes the result.

```bash
superdeck-deploy github-pages [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--branch, -b` | `gh-pages` | Branch to publish into |
| `--message, -m` | `Publish SuperDeck app to GitHub Pages` | Commit message |
| `--[no-]push` | `true` | Push to `origin` after committing |
| `--[no-]build` | `true` | Run `flutter build web` first |
| `--build-dir` | `build/web` | Built web assets directory |
| `--app-dir` | `.` | Flutter app directory to build |
| `--base-href` | auto | Override the auto-detected base href |
| `--dry-run` | off | Plan only; make no changes |

### `firebase`

Deploys to Firebase Hosting via the `firebase` CLI. Expects a built web app and
a `firebase.json` in `--app-dir`.

```bash
superdeck-deploy firebase [--app-dir demo] [--project my-project] [--channel preview]
```

## Programmatic use

The targets are exported from `package:superdeck_deploy/superdeck_deploy.dart`
(`GitHubPagesTarget`, `FirebaseTarget`) for use in custom tooling.
