# Deploy Package – Implementation Plan (Breaking Change)

## Executive Summary

Extract all SuperDeck publishing/deployment logic into a new, standalone
package: **`packages/deploy`** (`superdeck_deploy`). Today the CLI ships only
`build` and `setup`. The publishing surface that used to live in the CLI (the
`publish` command for GitHub Pages) was **removed at the 1.0 release** (commit
`c849878`, "Release/next") and now exists only in git history. The repo's other
deployment path is the Firebase Hosting GitHub Actions workflow that ships the
`demo` app to https://superdeck-dev.web.app.

This plan rebuilds the publishing flow **fresh** inside a dedicated package with
its own executable, removes deployment concerns from `superdeck_cli`, and makes
`superdeck_deploy` the single home for "ship a deck somewhere" logic (GitHub
Pages now, Firebase Hosting workflows owned/driven from here too).

This is intentionally a **breaking change**: `superdeck publish` will no longer
exist on the `superdeck` CLI. Deployment moves behind a separate executable.

## Current State (Findings)

### What exists today
- `packages/cli` — commands: `build`, `setup` only. Wired in
  `packages/cli/lib/runner.dart` (registers `BuildCommand`, `SetupCommand`).
- `packages/builder` — pure build logic (`DeckBuilder`, parsers). No publishing.
- `packages/core` — Dart-only primitives. No publishing.
- `packages/superdeck` — Flutter widgets, plus `src/capture/` and
  `src/thumbnails/` (runtime image capture for thumbnails — **not** deployment;
  out of scope).
- `.github/workflows/firebase-hosting-merge.yml` and
  `firebase-hosting-pull-request.yml` — deploy `demo` to Firebase Hosting.
- `demo/firebase.json`, `demo/.firebaserc` — Firebase Hosting config.
- `docs/guides/cli-reference.mdx` — a "Deploying to GitHub Pages" section that
  documents a **manual** Actions pipeline (no SuperDeck command involved).

### What was removed at 1.0 (recoverable from git, used as reference only)
- `packages/cli/lib/src/commands/publish_command.dart` (664 lines) — publish a
  built Flutter web app to GitHub Pages:
  - Validates branch name (command-injection guard).
  - Auto-detects `--base-href` as `/<repo>/` from the git remote.
  - Swaps in a custom loading `index.html` (with backup + guaranteed restore).
  - `flutter build web --release` (configurable example dir / output dir).
  - Creates a temporary **git worktree** on the target branch (`gh-pages`),
    or an orphan branch if it doesn't exist.
  - Copies `build/web`, writes `.nojekyll`, commits, optionally pushes.
  - Prints the resulting `https://<user>.github.io/<repo>/` URL.
  - Guaranteed cleanup (worktree removal + index.html restore) in `finally`.
  - Dependencies: `dart:io`, `args`, `mason_logger`, `path`, plus local
    `utils/logger.dart` and `utils/templates.dart` (`customIndexHtml`).
    **No dependency** on `core`, `builder`, or `superdeck`.
- `packages/cli/lib/src/commands/version_command.dart` — trivial version print.
- `packages/cli/lib/src/utils/templates.dart` — `customIndexHtml` template
  (only consumed by publish).

### Stale documentation to fix
- `AGENTS.md` / `CLAUDE.md` still describe the CLI as
  `cli/  # superdeck CLI tool (setup, build, publish, version)`. The `publish`
  and `version` commands no longer exist. These references must be corrected as
  part of this change.

## Decisions Made

| # | Decision | Choice |
|---|----------|--------|
| 1 | Package shape | **Standalone CLI package** `superdeck_deploy` with its own `bin/main.dart` executable (`superdeck-deploy`). Fully out of `superdeck_cli`. |
| 2 | Scope | **GitHub Pages publish** + **Firebase Hosting workflows**. (The `version` command is **not** in scope — it stays out / belongs to the CLI if revived.) |
| 3 | Source of publish logic | **Rewrite fresh**, using the removed `publish_command.dart` as reference for the proven git-worktree / index.html / base-href flow. |

## Target Design

### New package: `packages/deploy`

```
packages/deploy/
  pubspec.yaml                 # name: superdeck_deploy
  bin/
    main.dart                  # executable entrypoint: superdeck-deploy
  lib/
    superdeck_deploy.dart      # single barrel (relative exports)
    src/
      runner.dart              # DeployRunner extends CommandRunner<int>
      commands/
        base_command.dart      # shared DeployCommand base (logger, helpers)
        github_pages_command.dart   # `superdeck-deploy github-pages`
        firebase_command.dart       # `superdeck-deploy firebase`
      git/
        git_runner.dart        # thin Process wrapper + safe query helpers
        worktree.dart          # create/cleanup git worktree, orphan branch
      targets/
        github_pages.dart      # build-web + worktree + .nojekyll + push
        firebase.dart          # drive firebase deploy of a web build
      web/
        build_web.dart         # `flutter build web` wrapper, base-href logic
        index_html_template.dart    # customIndexHtml + backup/restore
      utils/
        branch_validation.dart # injection-safe branch name validation
        logger.dart            # minimal mason_logger wrapper (no builder dep)
        constants.dart         # deployToolName, version
  test/
    src/
      commands/github_pages_command_test.dart
      commands/firebase_command_test.dart
      git/worktree_test.dart
      utils/branch_validation_test.dart
      web/build_web_test.dart
  README.md
  analysis_options.yaml
  dart_test.yaml
```

### `pubspec.yaml`

```yaml
name: superdeck_deploy
description: Deployment tooling for SuperDeck presentations (GitHub Pages, Firebase Hosting)
version: 1.0.0
homepage: https://github.com/btwld/superdeck
documentation: https://docs.page/btwld/superdeck

executables:
  superdeck-deploy: main

environment:
  sdk: ">=3.10.0 <4.0.0"

dependencies:
  args: ^2.6.0
  path: ^1.9.0
  mason_logger: ^0.3.1

dev_dependencies:
  dart_code_metrics_presets: ^2.19.0
  lints: ^5.0.0
  test: ^1.25.8
```

Notes:
- A **pure Dart** package (no Flutter SDK dependency). It shells out to
  `flutter build web` and `firebase` rather than importing them, so it stays
  light and publishable like `superdeck_cli`.
- It does **not** depend on `superdeck_core` / `superdeck_builder`. Building the
  deck (`superdeck build`) remains the CLI's job and is a documented prerequisite
  step; `deploy` only ships the resulting web output. (A future iteration could
  add an optional `superdeck_cli` dependency to chain `build` automatically — see
  Open Questions.)

### Command surface

```
superdeck-deploy github-pages [options]
superdeck-deploy firebase [options]
superdeck-deploy --version
```

**`github-pages`** (rewrite of the removed publish command):

| Flag | Default | Purpose |
|------|---------|---------|
| `--branch, -b` | `gh-pages` | Target branch to publish into |
| `--message, -m` | `Publish SuperDeck app to GitHub Pages` | Commit message |
| `--push / --no-push` | `true` | Push to remote after commit |
| `--build / --no-build` | `true` | Run `flutter build web` first |
| `--build-dir` | `build/web` | Built web assets directory |
| `--app-dir` | `.` | Flutter app directory to build (was `--example-dir`) |
| `--base-href` | auto | Override the auto-detected `/<repo>/` base href |
| `--dry-run` | `false` | Plan only; make no changes |

Behavior preserved from the proven flow: branch-name validation, base-href
auto-detection from the git remote, custom `index.html` swap with
backup/restore, git worktree (or orphan branch) isolation, `.nojekyll`,
guaranteed cleanup in `finally`, and final Pages URL output.

**`firebase`**:
- Thin wrapper that runs `firebase deploy` (or
  `firebase hosting:channel:deploy`) against a target app dir, expecting the
  web build + `firebase.json` to exist (matching `demo/`'s setup).
- Initial implementation mirrors what the GitHub Actions workflow does today, so
  the workflow can be simplified to call `superdeck-deploy firebase` instead of
  inlining the Firebase action steps (see next section).

### Firebase Hosting workflows ownership

- Keep `demo/firebase.json` + `demo/.firebaserc` where they are (Firebase
  expects them at the hosting root).
- Update `.github/workflows/firebase-hosting-merge.yml` and
  `firebase-hosting-pull-request.yml` to activate `superdeck_deploy` and drive
  deployment through it, instead of duplicating build/deploy steps inline. The
  `FirebaseExtended/action-hosting-deploy` action may remain for the actual
  upload + PR preview comment (it integrates with GitHub), with the
  **build** half (`superdeck build`, `flutter build web`) standardized via the
  deploy package. The package becomes the documented, single source of truth for
  "how SuperDeck deploys."
- Document both targets (GitHub Pages + Firebase) in the package README and in
  `docs/guides/`.

## Breaking Changes & Migration

1. **`superdeck publish` is gone for good** on the `superdeck` CLI — replaced by
   the separate `superdeck-deploy` executable. (It was already removed at 1.0,
   so no currently-published CLI behavior regresses, but docs/users that
   referenced it must move to the new tool.)
2. **New executable & activation**: users run
   `dart pub global activate superdeck_deploy` and then `superdeck-deploy
   github-pages`.
3. **Flag rename**: `--example-dir` → `--app-dir` (clearer; the old name leaked
   the framework's `example/` history).
4. **Docs**: the manual GitHub Actions snippet in
   `docs/guides/cli-reference.mdx` gains a "one-command" alternative using
   `superdeck-deploy`.

Provide a clear migration note in the CHANGELOG and the deploy README.

## Workspace / Tooling Integration

- Melos auto-discovers `packages/*`, so `packages/deploy` is picked up by
  `melos bootstrap` with no `melos.yaml` change required.
- Add `analysis_options.yaml` pointing at `shared_analysis_options.yaml` (match
  the other packages) so it's covered by `melos run analyze` /
  `analyze:dcm`.
- Add a `dart_test.yaml` mirroring the CLI's so `melos run test` runs it.
- Member ordering, snake_case files, relative intra-package imports, single
  barrel — all per `AGENTS.md`.
- `.pubignore` for publish-readiness (the 1.0 release added these for every
  publishable package).

## Testing Strategy

Mirror `lib/src/` under `test/src/` (repo convention). Cover:
- **branch_validation_test** — accepts valid branches; rejects empty, leading
  `-`, `..`, whitespace/control chars (the security guard).
- **build_web_test** — base-href auto-detection from HTTPS and SSH remote URLs;
  username.github.io special-casing; fallback URL.
- **worktree_test** — worktree add/remove + orphan-branch path, using a temp git
  repo fixture; assert cleanup runs even on failure.
- **github_pages_command_test** — `--dry-run` makes no changes and prints the
  planned actions; index.html backup is restored on both success and failure
  paths; `.nojekyll` is written.
- **firebase_command_test** — argument wiring + dry-run; mock the `firebase`
  process invocation.
- Inject a fake process runner / logger (as the CLI tests already do) so tests
  don't shell out for real.

CI: the existing `melos run analyze` + `melos run test` jobs in
`.github/workflows/test.yml` will cover the new package automatically once it's
in the workspace; verify the matrix includes it.

## Documentation Updates

- New `packages/deploy/README.md` — install, `github-pages`, `firebase`,
  flags, examples.
- `docs/guides/cli-reference.mdx` — replace/augment the "Deploying to GitHub
  Pages" section to show `superdeck-deploy github-pages` as the recommended
  path, keep the raw Actions snippet as the manual alternative.
- Possibly a new `docs/guides/deploying.mdx` consolidating both targets; wire it
  into `docs.json`.
- Fix `AGENTS.md` / `CLAUDE.md` package descriptions (remove the stale
  `publish, version` claim from the CLI; add the `deploy` package and its role
  to the Project Structure section).
- `CHANGELOG.md` — note the new package + breaking migration.

## Phased Implementation Plan

### Phase 1 — Scaffold the package (0.5–1 day)
- Create `packages/deploy` skeleton: `pubspec.yaml`, barrel, `bin/main.dart`,
  `DeployRunner`, `base_command.dart`, minimal `logger.dart`, `constants.dart`,
  `analysis_options.yaml`, `dart_test.yaml`, `README.md`.
- `melos bootstrap`; confirm `melos run analyze` sees it and
  `superdeck-deploy --help` runs.

### Phase 2 — GitHub Pages target (1–2 days)
- Implement `web/build_web.dart` (base-href detection + `flutter build web`).
- Implement `web/index_html_template.dart` (template + backup/restore).
- Implement `git/git_runner.dart` + `git/worktree.dart`.
- Implement `targets/github_pages.dart` + `commands/github_pages_command.dart`
  with full flag set, `--dry-run`, and guaranteed cleanup.
- `utils/branch_validation.dart`.
- Tests for all of the above.

### Phase 3 — Firebase target (0.5–1 day)
- Implement `targets/firebase.dart` + `commands/firebase_command.dart` wrapping
  `firebase deploy` / channel deploy.
- Tests (dry-run + arg wiring with a mocked runner).

### Phase 4 — Workflow + CI integration (0.5 day)
- Update `firebase-hosting-merge.yml` / `firebase-hosting-pull-request.yml` to
  drive the build through `superdeck_deploy`.
- Verify `test.yml` analyze/test jobs include the new package.

### Phase 5 — Docs, cleanup, release-readiness (0.5 day)
- README + docs guide + `docs.json` wiring.
- Fix stale `AGENTS.md` / `CLAUDE.md` / CHANGELOG references.
- Add `.pubignore`; run `dart pub publish --dry-run` for the new package.
- `melos run fix` + `melos run analyze` + `melos run test` green.

## File Changes Summary

### New (package)
- `packages/deploy/pubspec.yaml`
- `packages/deploy/bin/main.dart`
- `packages/deploy/lib/superdeck_deploy.dart`
- `packages/deploy/lib/src/runner.dart`
- `packages/deploy/lib/src/commands/{base_command,github_pages_command,firebase_command}.dart`
- `packages/deploy/lib/src/git/{git_runner,worktree}.dart`
- `packages/deploy/lib/src/targets/{github_pages,firebase}.dart`
- `packages/deploy/lib/src/web/{build_web,index_html_template}.dart`
- `packages/deploy/lib/src/utils/{branch_validation,logger,constants}.dart`
- `packages/deploy/test/src/**` (mirrored tests)
- `packages/deploy/{README.md,analysis_options.yaml,dart_test.yaml,.pubignore}`

### Modified
- `.github/workflows/firebase-hosting-merge.yml`
- `.github/workflows/firebase-hosting-pull-request.yml`
- `docs/guides/cli-reference.mdx` (+ optional `docs/guides/deploying.mdx`, `docs.json`)
- `AGENTS.md` / `CLAUDE.md` (Project Structure + Quick Reference)
- `CHANGELOG.md`

### Untouched
- `packages/cli`, `packages/builder`, `packages/core`, `packages/superdeck`
  source (the CLI already lacks publish; nothing to remove). Only docs that
  reference the old CLI publish/version commands change.

## Risks & Mitigations

- **Git worktree edge cases** (dirty target branch, existing worktree, orphan
  creation): port the proven 1.0 flow's guarded cleanup; cover with temp-repo
  tests.
- **`flutter` / `firebase` not on PATH** in user environments: detect and emit a
  clear, actionable error instead of a raw `ProcessException`.
- **Pure-Dart vs needing Flutter**: keep `deploy` pure Dart by shelling out;
  avoids pulling the Flutter SDK into a publishable tool.
- **Command-injection via branch name**: reuse the strict validation regex from
  the reference implementation; unit-test rejection cases.

## Open Questions (non-blocking)

1. Should `superdeck-deploy github-pages` optionally run `superdeck build`
   itself (adding a `superdeck_cli` dependency), or keep "build first" as a
   documented prerequisite? (Plan assumes prerequisite for a clean dependency
   graph.)
2. Should the Firebase workflows fully delegate to `superdeck-deploy firebase`
   (replacing `action-hosting-deploy`), or keep the GitHub-integrated action for
   PR preview comments and only standardize the build half? (Plan assumes the
   latter for now.)
3. Is `version` truly dropped, or revived later as `superdeck version` in the
   CLI? (Out of scope per decisions; noted for tracking.)
