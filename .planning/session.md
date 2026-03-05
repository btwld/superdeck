# SuperDeck Session

## Purpose
This is the live session and handoff document for ongoing work in the SuperDeck repository.

Agents should read this file before substantive work and update it as work progresses.

## Current Focus
- Validate the v2 rewrite plan against the actual current implementation.
- Preserve the real v1 feature surface before making architecture changes.
- Keep rewrite planning grounded in code, docs, and tests rather than assumptions.

## Canonical Planning Docs
- `.planning/rewrite-v2-full-plan.md`
- `.planning/rewrite-v2-feature-matrix.md`
- `.planning/rewrite-v2-parser-semantics.md`

## Current State
- The v2 rewrite plan has been restored locally and reviewed against the current codebase.
- A feature validation matrix exists and maps current behavior to:
  - implementation refs
  - v2 ownership
  - parity decision
  - validation gate
  - migration notes
- `AGENTS.md` now requires agents to use:
  - `dart-flutter` for repository work
  - `code-simplifier` for code changes, reviews, refactors, and rewrite work
- `.planning/rewrite-v2-parser-semantics.md` now exists and freezes the parser-level v2 contract from current code/tests.
- Parser-level decisions now frozen:
  - frontmatter must be YAML-map-only
  - invalid YAML and missing frontmatter closing delimiters are hard errors
  - canonical markdown block syntax is `@block`
  - canonical semantic note field is `notes`
  - HTML comments are authoring notes, not retained renderable markdown semantics
- `.planning/rewrite-v2-feature-matrix.md` has been updated so frontmatter extraction and comment extraction are no longer `covered-open`.
- Planning docs have now been spot-audited against implementation again.
- Two stale claims were corrected:
  - fenced-code handling was overstated as backtick/tilde-inconsistent even though opener/closer parsing is already mostly shared
  - error-deck fallback was overstated as the general build-failure path even though build failures usually leave the last good deck in place and only update `build_status.json`
- A second audit pass corrected additional runtime-surface wording:
  - file-backed deck loading is gated by `kCanRunProcess` (`debug && !web && !test`), not by generic process capability
  - `styles.yaml` merge exists via `StyleConfigLoader`, but is not automatic runtime startup behavior today
- `.planning/rewrite-v2-parser-semantics.md` now includes a feature validation audit that distinguishes:
  - code+test validated features
  - code/test features with docs drift
  - implemented features that still lack direct parser fixtures
  - implemented features that still lack authoring docs
- The parser validation audit has been expanded into a stage-by-stage feature inventory tied to concrete test suites and implementation files.
- Authoring docs have been realigned with the parser audit:
  - `template` frontmatter is now documented
  - escaped directives via `_@` are now documented
  - HTML-comment speaker notes are now documented
  - `@block` is now the only public markdown-block syntax taught in docs/examples/templates
  - `@qrcode` argument docs were corrected to match the implementation
- High-level docs, starter templates, READMEs, and demo decks now teach only `@block` on the public/user-facing surface.

## Open Decisions To Freeze
1. Serialized `comments` -> `notes` migration:
   - parser semantics are frozen to `notes`
   - serialized artifact/API migration details still need to be specified
2. `superdeck.yaml` strictness:
   - unify CLI/runtime behavior
3. `styles.yaml` placement:
   - keep runtime-side or move later into build-time compilation
4. `watchForChanges` migration:
   - compatibility shim vs hard migration to explicit watch tooling

## Recommended Next Steps
1. Create `.planning/rewrite-v2-parser-semantics.md`
   - completed
2. Create `.planning/rewrite-v2-contract-migration-matrix.md`
   - lock artifact renames, API renames, and migration behavior
3. Turn the remaining `covered-open` items in `.planning/rewrite-v2-feature-matrix.md` into explicit decisions

## Session Log

### 2026-03-05
- Removed the legacy markdown-block alias from the public/user-facing documentation surface while preserving implementation compatibility:
  - updated `docs/`, top-level `README.md`, `packages/superdeck/README.md`, the CLI starter deck template, and demo markdown decks to show only `@block`
  - remaining legacy-alias references are now limited to implementation comments, tests/fixtures, and internal agent/planning context where the backward-compatibility contract still needs to be described
- Verification for the public-docs sweep:
  - searched the public/user-facing surfaces for the legacy block alias across `docs/`, READMEs, the CLI starter deck template, and demo markdown decks
  - `git diff --check`
  - result: no remaining public/user-facing legacy-alias references and diff hygiene clean
- Verified the nested fenced-code doc examples from a markdown/MDX perspective:
  - the standard ` ````markdown ... ```dart ... ``` ... ```` ` pattern is valid and renders correctly because the outer fence is longer than the inner fence
  - fixed one malformed docs example in `docs/examples.mdx` where an inner closing fence incorrectly had trailing `{.code}`, which is not valid fenced-code closing syntax
  - verification: targeted fence scan across the main docs surfaces plus `git diff --check`, both clean
- Closed the remaining parser-semantics documentation follow-up:
  - tutorial/example/reference docs now lead with canonical `@block` examples and label the legacy block form only as compatibility behavior
  - fenced-code docs now mention brace-free option headers only as legacy compatibility while keeping braced headers canonical
  - `.planning/rewrite-v2-parser-semantics.md` no longer tracks active docs drift for parser semantics; it now records documentation alignment notes instead
- Verification for the docs-only follow-up:
  - `git diff --check`
  - result: clean
- Continuing the remaining parser-semantics follow-up items:
  - convert tutorial/example docs from legacy-block-first teaching to canonical `@block`-first examples while keeping backward compatibility in the implementation
  - decide whether brace-free fenced-code option headers stay implementation-only compatibility or get a brief legacy-compatibility note in docs
- Completed the strict-proof parser-semantics audit pass:
  - added direct characterization fixtures for widget shorthand normalization, explicit `@widget { name: ... }`, `_@` escaped directives, frontmatter post-extraction trim normalization, directive/fenced-code non-map option collapse, fenced-code brace-free YAML-map headers, and the trailing post-last-directive trim asymmetry
  - rewrote `.planning/rewrite-v2-parser-semantics.md` into explicit `Observed v1 behavior` and tagged `V2 decision` lanes with per-stage proof refs
  - reclassified fenced-code brace-free option acceptance as validated current behavior with intentional v2 tightening instead of leaving it as an undocumented parser assumption
  - added user-doc coverage for Dart fenced-code formatting in standard build/watch flows
  - added strict-proof sign-off criteria to the parser semantics doc; there are now zero `implemented with test gap` rows remaining
- Ran the full focused parser validation set with the pinned FVM SDK:
  - `packages/builder`: `../../.fvm/flutter_sdk/bin/dart test test/src/parsers test/src/slide_processor_test.dart test/src/markdown_utils_test.dart`
  - `packages/core`: `../../.fvm/flutter_sdk/bin/dart test test/src/tag_tokenizer_test.dart test/src/utils/code_fence_test.dart test/src/utils/yaml_utils_test.dart test/src/models/block_model_test.dart test/src/models/deck_model_test.dart test/src/models/slide_model_test.dart`
  - result: all tests passed
- Starting strict-proof implementation for `.planning/rewrite-v2-parser-semantics.md`: close every remaining parser-proof gap with direct characterization tests, then regrade the semantics doc so no current-behavior claim remains inference-only.
- Starting a deeper parser-contract audit pass to verify that `.planning/rewrite-v2-parser-semantics.md` is correct feature-by-feature, including processing order and remaining public-doc drift.
- Restored `.planning/rewrite-v2-full-plan.md`.
- Added `.planning/rewrite-v2-feature-matrix.md` to validate rewrite completeness against the current implementation.
- Updated `AGENTS.md` to require checking this file first and to require `dart-flutter` plus `code-simplifier` for repo work.
- Resumed rewrite planning to create `.planning/rewrite-v2-parser-semantics.md`.
- Current task focus: extract parser rules from code/tests first so the v2 parser contract is explicit and testable.
- Added `.planning/rewrite-v2-parser-semantics.md` from the current parser code/tests.
- Froze parser-level v2 decisions for frontmatter strictness, shared fence handling, `@block` canonicalization, and `notes` semantics.
- Documented parser quirks that should not be preserved as v2 contract:
  - silent fallback on missing frontmatter closing delimiters
  - escaped-directive handling after token offset calculation
  - duplicated note semantics in both comment metadata and markdown content
  - inconsistent trimming during section aggregation
- Audited the planning docs against implementation and corrected two stale claims in the rewrite plan/matrix:
  - fenced-code handling is mostly shared today and should be described as multi-layered rather than backtick/tilde-inconsistent
  - error-deck fallback currently applies to generated-deck load failures, not to all markdown/build failures
- Ran a second audit pass and corrected two more current-state claims:
  - runtime deck loading mode is `kCanRunProcess`-gated rather than generic “process-capable”
  - `styles.yaml` support is currently opt-in through `StyleConfigLoader`, not automatic app bootstrap behavior
- Ran a parser-focused feature audit and updated `.planning/rewrite-v2-parser-semantics.md` with explicit validation status.
- Remaining parser-surface validation gaps now called out explicitly:
  - explicit `@widget` and shorthand widget directives need direct parser fixtures
  - `_@` escaped directives still have no dedicated parser fixtures
  - public docs still taught the legacy block form while v2 planning froze canonical `@block`
- Follow-up doc updates reduced the remaining parser-surface docs drift:
  - `template`/`template: none`, `_@`, and HTML-comment notes are now documented
  - remaining authoring drift was primarily that docs still led with the legacy block form while v2 planning froze `@block` as canonical
- Expanded the parser validation audit into a stage-by-stage feature matrix covering slide splitting, frontmatter, directive tokenization, normalization, comments, and fenced-code transforms.
- Updated high-level docs (`docs/index.mdx`, `docs/guides/superdeck-overview.mdx`, `docs/reference/block-types.mdx`) so `@block` is no longer absent from top-level syntax summaries.
- Ran the parser-focused verification subset with the pinned FVM SDK:
  - `packages/builder`: `../../.fvm/flutter_sdk/bin/dart test test/src/parsers test/src/slide_processor_test.dart test/src/markdown_utils_test.dart`
  - `packages/core`: `../../.fvm/flutter_sdk/bin/dart test test/src/tag_tokenizer_test.dart test/src/utils/code_fence_test.dart test/src/models/slide_model_test.dart test/src/models/deck_model_test.dart`
  - result: all tests passed
- Ran a deeper parser-contract audit pass and corrected the remaining contract drift:
  - the parser semantics doc now treats fenced-code transforms as task-driven/flow-dependent rather than an unconditional parser stage
  - section aggregation coverage is now explicitly represented in the parser validation audit
  - parser-semantics wording is now feature-first and no longer mixes in future package ownership boundaries
- Reduced broader legacy-block teaching drift in tutorial-style docs by adding `@block`-first notes to:
  - `docs/getting-started.mdx`
  - `docs/tutorials/block-layouts.mdx`
  - `docs/examples.mdx`
- Verified the focused `section_parser_test.dart` and builder-side `tag_tokenizer_test.dart` subset again after the deeper audit; all tests passed.
- Ran another parser-semantics validation pass and tightened one remaining omission:
  - the audit now explicitly treats `scrollable` as part of the validated typed block-option surface alongside `flex` and `align`
- Ran an additional deep parser-semantics audit and documented a few remaining normalization details that had not been written down explicitly:
  - frontmatter extraction/materialization currently trim-normalizes the remaining slide markdown body
  - directive option braces may start after arbitrary intervening whitespace/newlines, not just same-line or next-line
  - section aggregation currently trim-normalizes the trailing post-last-directive markdown span only
  - fenced-code parsing currently trim-normalizes fenced content before build tasks receive it
  - the typed parser contract now explicitly includes block-level `align` / `flex` / `scrollable` fields for both markdown and widget blocks
- Starting a second audit pass over the rewrite planning docs to verify non-parser runtime, CLI, and API claims against the current implementation.
- Starting a parser-focused feature audit to validate `.planning/rewrite-v2-parser-semantics.md` against code, tests, and user docs while ignoring package-layout planning for now.

## Update Rules
- Keep entries concise and factual.
- Prefer updating this file over leaving important context only in chat history.
- Do not duplicate full design documents here; link to them.
- Record decisions, constraints, risks, and next steps that another agent would need to continue cleanly.
