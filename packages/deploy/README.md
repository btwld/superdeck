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
from the `origin` remote, installs a loading `index.html`, and commits/pushes
the result, extending the branch's existing history rather than orphaning it.

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
| `--cname` | preserve | Custom domain to write to `CNAME` |
| `--dry-run` | off | Plan only; make no changes |

### GitHub Pages conventions

Each publish applies the conventions GitHub Pages needs for a Flutter web app:

- **`.nojekyll`** — disables Jekyll so Flutter's `assets/`, `canvaskit/`, and
  underscore-prefixed files are served as-is.
- **`404.html`** — a copy of `index.html`, so client-side (path-based) routes
  deep-link correctly; Pages serves `404.html` for unknown paths.
- **`CNAME`** — a custom domain set via the Pages UI (or a previous `--cname`)
  is preserved across publishes. Pass `--cname deck.example.com` to set one, or
  commit `web/CNAME` to manage it from source.

## Firebase Hosting

For Firebase, use the official tooling rather than this package:

- **CI:** the [`FirebaseExtended/action-hosting-deploy`](https://github.com/FirebaseExtended/action-hosting-deploy)
  GitHub Action (handles auth, live deploys, and PR preview channels). Set it up
  with `firebase init hosting:github`.
- **Local:** `firebase deploy --only hosting`.

## Programmatic use

`GitHubPagesTarget` is exported from
`package:superdeck_deploy/superdeck_deploy.dart` for use in custom tooling.
