# AI generation session status — 2026-07-14

Status: Tasks 1–6, the 12-theme family, representative render qualification,
and deterministic ten-slide generation are verified; repeated real 10/15/20
quality runs and final human acceptance remain open

This document is the resume point for the iterative SuperDeck AI-generation
work. It separates what is implemented and verified from what still needs live
rendered evidence. The implementation cleanup is complete, but the larger
prompt-quality objective is not complete yet.

## Git checkpoint

- Branch: `leoafarias/iterative-ai-generation`
- Remote: `origin/leoafarias/iterative-ai-generation`
- Checkpoint: `cf463294c09f54e0133e4ff7ce68f228a3c4b1b5`
- Commit: `feat: improve AI deck generation quality`
- Base: `8b12ab009919fcbc9824d1d3719760b47fa03942`
  (`origin/main` when the branch was created)
- Checkpoint size: 86 files, 12,452 insertions, 1,764 deletions
- Live artifact output is ignored and remains local under
  `packages/playground/test_live/ai_generation/artifacts/`.

The checkpoint was pushed before this housekeeping pass. The current working
tree contains the subsequent generation/capture cleanup, regression tests,
planning corrections, and static-analysis hygiene changes. It is intentionally
not folded back into the checkpoint commit yet.

## Product and architecture decisions to preserve

- Keep a plan-first pipeline: one hierarchical deck blueprint followed by one
  sequential request per slide.
- Keep previous-slide, next-slide, section, and compact design-ledger context so
  visual and narrative decisions remain coherent across 10–20 slides.
- Keep `gemini-3-flash-preview` as the default outline and slide model.
- Keep explicit thinking budgets disabled for generation latency.
- Keep the canonical runtime `Slide` and Markdown contracts stable. Generation-
  only request, plan, theme, and validation contracts can evolve directly.
- Keep deterministic checks as the production gate. Model-authored visual review
  remains opt-in and informational until it correlates with human review.
- Do not introduce a mandatory critic call or parallel slide composition until
  measurements justify the additional cost or loss of continuity.

## Implemented at the checkpoint

### Request and planning

- A typed generation request carries exact slide count, user intent, palette,
  fonts, design direction, density, and grounded elements.
- The outline schema supports sections, narrative roles, assertions, content
  units, composition families, treatments, density, and a deck design system.
- Plan validation enforces requested counts, section membership, font resolution,
  palette contrast, layout rhythm, and grounded element intent.

### Slide composition

- The whole-deck generation request was replaced with sequential single-slide
  composition and slide-scoped repair.
- Prompt assembly is centralized and deterministic. Each request receives only
  the relevant composition example and exact grounded element source.
- Model-facing schemas expose the supported SuperDeck block surface while Dart
  validation retains bounds that Gemini cannot accept in the most complex
  nested slide schema.
- Generated-slide validation covers parseability, non-empty content, planned
  composition, density, tables, title/display treatment, exact element counts,
  domains, numeric facts, and source commitments.

### Design and typography

- One typography catalog is shared across generation and customization.
- One injectable presentation-theme catalog now owns stable IDs/versions,
  selection descriptions/tags, complete runtime recipes, and exact resolution.
  The same profile-owned instance builds the Wizard prompt, GenUI schemas and
  examples, selection cards, summary cards, generation validation, runtime
  mapping, and live artifacts. A custom-ID regression proves those surfaces do
  not silently fall back to the default catalog.
- The outline model receives only a deterministic compact candidate shortlist
  and returns one eligible ID. Dart attaches the version, density, and validated
  user-only brand override before any slide is composed.
- The former model-authored style object has been removed from the generation
  plan, prompt, serializer, runtime result, Wizard mapping, and live artifact
  reader. Twelve materially distinct themes work end to end and resolve all
  seven semantic slide treatments.
- Known Google families and application-registered bundled custom families are
  supported; invented families fail explicitly.
- Generated palettes and semantic treatments map into presentation-scale
  `DeckOptions`, including tables, lists, quotes, code, links, and light/dark
  contrast behavior.

### Observability and live evaluation

- Generation emits structured trace events for model, phase, request/response,
  semantic attempt, transport attempt, timing, typed validation, and slide
  position while retaining the legacy attempt field for JSON compatibility.
- One shared executor now enforces run-wide provider-call, semantic-repair, and
  wall-clock budgets. Cooperative cancellation is connected to the generation
  command and lab lifecycles.
- The opt-in live harness supports fast smoke fixtures plus 10-, 15-, and
  20-slide quality fixtures.
- Each complete run can save the typed request, source brief, plan, prompts,
  responses, canonical JSON, Markdown, trace, metadata, slide PNGs, contact
  sheet, and machine-readable quality report.
- Captures resolve the selected font family instead of registering Roboto under
  an alias.
- Isolated capture now waits for explicitly registered asynchronous image/asset
  readiness within a bounded settle loop and reports pending labels on timeout.

## Fresh verification after cleanup

| Check | Result |
|---|---|
| `fvm dart run melos run build_runner:build --no-select` | Passed; generated files synchronized |
| Changed-file formatter and Dart fix previews | Passed; 35 Dart files checked, 3 formatted, nothing left for Dart fix |
| `fvm dart run melos run analyze:all --no-select` | Passed across 8 packages; Dart, DCM, unused-code, and unused-file gates clean |
| Focused generation/Wizard regressions | Passed; 99 tests |
| Focused capture/image/WebView regressions | Passed; 70 tests |
| `fvm dart run melos run test --no-select` | Passed across all 8 packages |
| Theme catalog/schema/Wizard contract proof | Passed; 15 focused tests |
| Broader theme/generation regressions | Passed; 76 focused tests |
| Saved 20-slide artifact replay | Passed current semantic validation and recaptured 20/20 slides |
| Contact sheet plus full-size slides 1, 12, 18, and 20 | Reviewed; no clipping, overflow, missing assets, or font substitution observed |
| `git diff --check` | Passed after discarding codegen-only trailing-blank-line churn |
| Focused AI/theme/Wizard regression suite after catalog injection fix | Passed; 187 tests |
| Deterministic ten-slide fake generation checkpoint | Passed; one outline plus ten slide calls, zero repairs, ten captures |
| Twelve-theme render qualification | Passed; 30 full-size captures, three contact sheets, and three opt-in golden baselines |
| Light/dark syntax contrast regression | Passed; resolved code backgrounds select the correct palette and every rendered token reaches at least 4.5:1 contrast |

Latest deterministic artifact evidence:

- `fake_checkpoint_10_2026-07-14T22-03-52.113007Z`
- `theme_qualification_2026-07-14T22-39-00.146149Z`

The build reports an existing compatibility warning: the Dart 3.12 SDK language
version is newer than analyzer language version 3.11. This did not fail code
generation, analysis, or tests and was not addressed by this feature branch.

Not yet verified:

- two successful live runs for every 10/15/20 quality fixture;
- a deterministic render-overflow signal for live capture;
- final human acceptance across fresh narrative, typography, visual balance,
  tables, elements, and cross-slide variation runs.

## Live artifact evidence

### Best current 20-slide artifact

`packages/playground/test_live/ai_generation/artifacts/visual_product_20_2026-07-14T12-53-20.929304Z/`

- Generated and captured 20/20 slides.
- Used ten composition families and the requested Montserrat/DM Sans pairing.
- Exact image and QR elements were preserved.
- Replayed under the cleanup implementation and passed current semantic
  validation, Markdown parsing, and 20/20 recapture.
- The regenerated contact sheet and representative full-size title, evidence,
  table, and CTA slides showed no clipping, overflow, missing assets, or font
  substitution during manual review.

### Latest completed 10-slide artifact

`packages/playground/test_live/ai_generation/artifacts/narrative_10_2026-07-14T13-17-58.436280Z/`

- Automated quality reporting passed at generation time.
- Manual review found the opening title clipped at the top.
- The run used 33 model requests: 14 outline-phase and 19 slide-phase requests,
  including substantial repair traffic.
- This artifact is evidence that structural validation alone is not a visual
  quality gate; it is not an accepted final result.

### 15-slide status

- Two decision/data runs were started but did not produce an accepted complete
  artifact.
- They exposed decimal tokenization and repeated targeted-repair timeout issues.
- Decimal identity is fixed and regression-tested. Timeout/repair policy remains
  unresolved.

There are approximately 60 MB of ignored local run artifacts. They were retained
because they contain useful failure evidence; do not delete them until the best
and known-bad examples are deliberately curated.

## Post-checkpoint housekeeping

- Corrected live artifact metadata so `requestCount` is the total across outline
  and slide phases, with both phase counts recorded separately.
- Added typed validation issues so hard factual/grounding failures remain
  blocking while soft design-quality findings remain diagnostic.
- Centralized model execution, bounded requests/repairs/time, split semantic
  versus transport retry tracing, and wired cooperative UI cancellation.
- Extracted standalone validator/helper and generated-style-mapping boundaries;
  retained the pipeline/workflow/repair part files because their private state
  is still one cohesive implementation.
- Replaced capture timing heuristics with bounded readiness registration for
  built-in cached and resolved asset images.
- Added debug-only Wizard access to the generation lab and documented offline
  artifact replay.
- Enabled the current DCM configuration in Playground and recorded 1,142 exact
  pre-existing findings in `dcm_baseline.json`; all new/unbaselined rules and
  unused-code/file checks pass.
- Kept generated live artifacts ignored and untouched.
- Regenerated code, formatted changed files, ran analyzer fix previews, passed
  full workspace analysis/tests, replayed the best 20-slide artifact, and
  inspected representative rendered output.

`dcm fix` does not honor the analysis baseline and still proposes broad legacy
rewrites in Playground. Do not run the repository-wide fix script on this branch
without deliberately accepting that separate migration; use changed-file
formatting plus analyzer/DCM gates for this incremental cleanup.

## Unresolved issues, in priority order

1. **Complete the live matrix.** Generate, replay, capture, and manually inspect
   fresh 10-, 15-, and 20-slide fixtures at least twice each.
2. **Tune from measured live outcomes.** Use trace request counts, typed issue
   distributions, contact sheets, and full-size slide review to decide whether
   prompt/schema changes are justified; avoid adding retries or critic calls by
   intuition alone.
3. **Complete the final regression audit.** Re-run codegen, focused and full
   tests, workspace analysis, `git diff --check`, and requirement-by-requirement
   plan review after any tuning from the live matrix.
4. **Curate retained artifacts.** Keep the accepted 20-slide and known-bad
   10-slide evidence, then remove redundant ignored runs once comparisons are
   complete.
5. **Review source-grounding structure after policy is settled.**
   `source_grounding.dart` is large because policy and tokenization are mixed.
   Split it only after hard versus soft behavior is explicit and covered by
   tests; a mechanical file split first would hide the policy problem.

## Resume sequence

1. Run fresh 10/15/20 fixtures twice each, review full-size slides and contact
   sheets, and update the quality plan with measured outcomes.
2. Tune prompts or schemas only for repeated measured failures, then rerun the
   deterministic gates and affected live fixtures.
3. Complete the final regression and plan audit. Keep deferred image-style work
   out of this pass unless it is separately activated.

## Useful commands

```bash
# Generate and validate code.
fvm dart run melos run build_runner:build --no-select
fvm dart run melos run analyze:all --no-select
fvm dart run melos run test --no-select

# Focused deterministic tests.
cd packages/playground
fvm flutter test test/features/ai/quick_agent --reporter expanded
fvm flutter test test/core/deck_customization_store_test.dart --reporter expanded

# Full large-deck live matrix. This uses the real API and writes ignored output.
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define-from-file=../../.env \
  --dart-define=LIVE_FIXTURE=large_deck_matrix \
  --reporter expanded

# Replay an existing artifact without another model generation call.
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define=LIVE_ARTIFACT=<artifact-directory> \
  --reporter expanded
```
