# Static analysis: what runs where

Maintainer notes, current as of 2026-09-21.

## The commands

| Command | What it runs |
| --- | --- |
| `melos run analyze` | `analyze:dart` then `analyze:dcm` |
| `melos run analyze:dart` | `dart analyze --fatal-infos` in every package |
| `melos run analyze:dcm` | `dcm analyze . --fatal-style --fatal-warnings` in every package that depends on `dart_code_metrics_presets` |
| `melos run analyze:all` | the above plus `dcm check-unused-files` and `dcm check-unused-code` |

Run `melos run <script> --no-select` in scripts and CI. Without the flag melos
prompts for a package and a non-interactive runner hangs on that prompt.

## What CI runs

The Test workflow ran `invertase/github-action-dart-analyzer` with
`fatal-infos: false` and `fatal-warnings: false`, before `pub get` and before
code generation. That reported strictly less than the local command, on a tree
whose generated files did not exist yet.

It now runs `melos run analyze:dart --no-select` after code generation, which
is exactly the first half of `melos run analyze`.

## The gap that remains: DCM in CI

`analyze:dcm` is not in CI. Running it needs the `dcm` binary on the runner
(`CQLabs/setup-dcm`) and a licence key in repository secrets. Until that is
configured, DCM findings are caught only on developer machines.

Closing it is one job step and one secret; it is not done here because this
change cannot verify a secret it cannot see.

## The other gap: the playground's DCM baseline

`packages/playground/dcm_baseline.json` (written 2026-07-15 with DCM 1.38.0)
suppresses findings that `melos run analyze` would otherwise fail on.

Removing the editor emptied a third of it: 187 suppressed findings across 21
files named code that no longer exists. Those entries were deleted — a stale
entry cannot hide a current finding, so pruning them is safe and it stops the
file from looking like more debt than it is. **468 suppressed findings remain**,
all naming live files.

Measured on 2026-09-21 by moving the baseline aside (630 findings at that
point, before the prune, on the tree that still had the editor):

Measured on 2026-09-21 by moving the baseline aside:

| Finding | Count |
| --- | --- |
| Prefer dot shorthands (enum prefixes, class instantiations, class prefixes) | 272 |
| Missing a blank line before `return` | 161 |
| Member ordering (fields, constructors, private/public methods) | 92 |
| Named arguments do not match declaration order | 33 |
| Avoid inferrable type arguments | 18 |
| Everything else, including 30 warning-level findings | 54 |

`dcm fix` resolves 601 of the 630 automatically. **Do not run it unreviewed:**
on this tree it also rewrote `Provider.of<DeckDocumentStore>(context)` to
`Provider.of(context)` at dependency-injection call sites, and produced one
file that no longer compiled (`genui_conversation_session.dart`, a
"move declaration closer to use" fix leaving a `final` potentially unassigned).
That sweep was tried during this work and reverted.

The 29 findings `dcm fix` cannot fix include real ones worth reading: a field
that is never disposed in `main.dart`, a loop that always exits after one
iteration in `superdeck_a2ui_transport.dart`, a function that always returns
null in `google_schema_adapter.dart`, and a missing `unknown` map entry in
`error_classifier.dart`.

**Recommended order when this is picked up:** fix the 29 by hand first, because
they are the ones that can be defects; then run `dcm fix` package by package
with the diff reviewed; then delete the baseline so the debt cannot grow back
unnoticed.
