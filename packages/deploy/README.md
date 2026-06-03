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

## Firebase Hosting

For Firebase, use the official tooling rather than this package:

- **CI:** the [`FirebaseExtended/action-hosting-deploy`](https://github.com/FirebaseExtended/action-hosting-deploy)
  GitHub Action (handles auth, live deploys, and PR preview channels). Set it up
  with `firebase init hosting:github`.
- **Local:** `firebase deploy --only hosting`.

## Programmatic use

`GitHubPagesTarget` is exported from
`package:superdeck_deploy/superdeck_deploy.dart` for use in custom tooling.
