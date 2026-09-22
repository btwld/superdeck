# SuperDeck architecture plan: adversarial audit

**Decision:** keep the main direction, but revise the execution plan before treating it as implementation-ready.

**Repository:** `conceptadev/superdeck`  
**Reviewed baseline:** `main@d160766c862a4ea7670a41c98f085bfae33a24f7`  
**Date:** 21 September 2026; second pass 22 September 2026  
**Status:** source and plan audit; new application regressions were not executed.

## Context

This document is an adversarial second pass over the earlier SuperDeck architecture review, action plan, and backlog. It checks those artifacts against Matt Pocock's `improve-codebase-architecture` and `codebase-design` guidance, the repository's `AGENTS.md`, and selected implementation files.

It is a correction addendum. It does not turn the earlier 36-item backlog into 36 confirmed defects or mandatory architecture changes. The earlier work used the skills' source guidance and vocabulary, but did not execute the complete tool-driven process described by the skill, including an independent sub-agent exploration pass and the full candidate grilling loop.

**The earlier artifacts are not in this repository.** The review, action plan, and backlog that this document corrects were never committed on any branch. `superdeck_architecture_audit_checks.json` records their SHA-256 hashes, but a maintainer cannot open them. References below to backlog items, PR groups, and task IDs such as `SD-32` cannot be verified from the repository. Either commit those artifacts beside this document or treat the findings below as the standalone record.

## Second pass: the skill's process, run against the code

On 22 September 2026 the skill's process was run directly on this baseline: scope by commit history, read the ADR and recorded decisions, explore the code, apply the deletion test to each suspect module, and write the candidate report. The report was written outside the repository, as the skill requires. Two departures from the skill: the exploration was done without a sub-agent, by maintainer instruction, and the grilling loop was not started because it needs the maintainer's choice of candidate.

Terms below follow the `codebase-design` glossary: module, interface, implementation, depth, seam, adapter, leverage, locality. The repository has no `CONTEXT.md`, so domain terms come from the code's own doc comments: deck, generated deck, saved deck, runtime, document, preview, artwork, Wizard, library.

### Candidates

| # | Candidate | Strength | Dependency category |
| --- | --- | --- | --- |
| 1 | Give deck publication one owner | Strong | in-process |
| 2 | Deepen the memory deck loader | Strong | in-process |
| 3 | One PDF export is one run | Worth exploring | local-substitutable |
| 4 | One notion of "is this run still current" | Speculative | in-process |

**1. Give deck publication one owner.** Two publishers write the same four stores by hand: `GeneratedDeckResultApplier` writes the document, the preview loader, and the theme; `DeckLibraryController.open` writes those three and binds the artwork owner. The rule "unbind the saved deck's artwork only once the generated deck is published" lives in a lambda in `wizard_page.dart`, which runs before the applier can abandon the result. Deletion test: delete the applier and its staging, queue, and eviction logic reappears in the Wizard controller; delete the lambda and the invariant vanishes, which is the saved-A/failed-B defect. Both concentrate, so the module earns its keep now. `DeckLibraryController` already documents itself as the owner of "which deck's artwork the renderer resolves", so it is the natural home. No new class is required. ADR-0001 keeps deck-owned artwork separate from derived thumbnails; the deepened module owns artwork binding only.

**2. Deepen the memory deck loader.** `MemoryDeckLoader` is about ten lines of implementation behind an interface that carries three hidden facts: subscribe before the first update or lose it (the eager-provider rule in `providers.dart`), `reload()` does nothing while `DeckSessionState.reload()` marks itself loading, and unchanged text never re-emits, so the retry button in `slide_page_content.dart` hangs. Deletion test: delete the loader and the three rules reappear in every publisher and in the app root. The deepening is for the loader to own its current state: late subscribers receive it, `reload()` re-emits it, and the ordering rule leaves the app root. No event bus and no new adapter.

**3. One PDF export is one run.** `PdfController` is reusable across exports, so `export()` resets run state before its `try` and nothing clears captured images in a `finally`. The dialog must dispose and recreate the controller when slides change, and `_handleExport` re-reads the controller field after its await, so it acts on whichever controller is current. Two `@visibleForTesting` members let tests reach past the interface. Capture already has two adapters, `SlideCaptureService` in production and a fake in tests, so that internal seam is real. The public interface of the plugin is two exports with one caller, so no public export-session seam is justified.

**4. One notion of "is this run still current".** The generation engine is the hottest area in commit history and is already deep: four entry points on `DeckGeneratorService` with about 4,000 lines behind them in part files. Run ownership is expressed four ways: an operation epoch in the Wizard controller, `isCancelled` closures polled about fifty times in the engine, an `isValid` guard in the applier, and a `revision` counter on `DeckDocumentStore` that nothing reads outside its own test. Not proposed now. Revisit if candidates 1 and 2 leave the guard plumbing painful.

**Looked at, not proposed.** The Markdown renderer, slide assembly, and Mermaid are decided in `renderer-and-assembly-evaluation.md` and ADR-0001; no friction found that warrants reopening them. `DeckLibrary` has a four-method interface and writes each file through a temporary sibling and a rename; it is deep enough. `deck_generator_pipeline_helpers_test.dart` tests past the engine's interface and should fold into service-level tests when next touched.

**Top recommendation:** candidate 1. It passes the deletion test today and fixes a confirmed defect. Candidate 2 is the smallest change if a one-file first slice is wanted.

### Size of the change

Estimates cover the focused slice of each candidate, with regressions. Lines are net source plus test lines.

| Candidate | Source files | Test files | Lines | Public interface change |
| --- | --- | --- | --- | --- |
| 1. Publication owner | 4 (`wizard_page.dart`, `generated_deck_result_applier.dart`, `deck_library_controller.dart`, `deck_document_store.dart`) | 3 | about 250 | none outside `packages/playground` |
| 2. Memory loader | 2 (`memory_deck_loader.dart`, `providers.dart` comment) | 2 | about 120 | none; `DeckLoader` unchanged |
| 3. PDF run, focused fix | 2 (`pdf_controller.dart`, `pdf_export_screen.dart`) | 2 | about 80 | none; barrel unchanged |
| 3. PDF run, full restructure | 2 | 2 | about 300 | none |
| 4. Run identity | not estimated | | | |

Total for the three focused slices: about 450 lines across eight source files and seven test files, all inside `packages/playground` and `packages/plugins/pdf`. No package in `packages/superdeck` or `packages/core` changes its interface. Each slice is independent and can ship as its own PR.

### Findings the first pass missed

- `DeckDocumentStore.revision` has no reader outside its own test. It is interface with no leverage. Delete it with candidate 1.
- The subscribe-before-publish rule leaks into the app root. The eager-provider comment in `packages/playground/lib/app/providers.dart` is a loader invariant living in the wrong module. Candidate 2 removes the need for it.
- Two test-only members on `PdfController` expose internal seams to tests. The skill's deepening notes say not to do this. Candidate 3 deletes them.
- `DeckLibraryController.refresh()` lacks the busy guard that `save()` and `open()` have, so it can interleave with them. Candidate 1's owner absorbs this fix.
- The first pass did not say whether it checked the commit-history hot spot. The second pass did: the generation engine is deep and needs no candidate.

### Corrections to this document's first pass

- The "Memory loader" section below speaks of replay behavior. Replay to late subscribers is the proposed deepening, not existing behavior. The loader has no replay today.
- "Thumbnail/artwork identity" appears in the fix track below with no finding section that explains it. It stays listed, but it needs a recorded finding before work starts.
- The first pass rated a neutral publication owner as conditional. The deletion test says the owner earns its keep now. The correction is in "Separate three work tracks" below.
- The rendered HTML copy beside this file is a second source of truth and drifts from it. The skill writes its report to a temporary directory so nothing lands in the repository. The HTML has not been updated with the second pass and should be removed.

## Findings that remain justified

### Active-deck publication

The Wizard releases the open saved deck before invoking the generated-result applier. That leaves a correctness-sensitive ownership rule in the caller. Keep the publication finding and add a regression for saved deck A followed by a failed or invalidated generated replacement B.

The desired invariant is: prepare a replacement completely, publish it only while it still owns the operation, and otherwise leave the previous deck coherent.

Verified on the baseline: `wizard_page.dart` line 123 calls `releaseOpenDeck()` before `apply()`. If the applier abandons or throws, deck A's text stays in the document store, but its artwork now resolves through the in-memory fallback and the "Save another copy" state is lost.

### Memory loader

`MemoryDeckLoader.reload()` is empty while runtime reload sets loading state to true. This is a direct contract mismatch. Fix it without inventing a generic event bus or changing every loader adapter.

If the fix adds replay to late subscribers, which the second pass recommends, it needs tests around the subscription handoff: no lost update, no duplicate replay to existing listeners, and no stale snapshot after a newer state.

### PDF lifecycle

Keep the focused PDF lifecycle work. The inspected export path has no terminal `finally` cleanup for captured PNG references and mutates shared run state before its `try` block.

However, narrow the architecture claim. The package's supported application-facing interface is already small: the public barrel exports the plugin and options, and the plugin opens the internal dialog. Application callers do not assemble the PageView, capture keys, and readiness scopes.

Therefore:
- keep focused cleanup, cancellation, and stale-callback fixes;
- treat a private capture-host extraction as conditional;
- do not add a public export-session abstraction merely to satisfy deep-module terminology.

The stale-callback defect, made concrete: `_handleExport` in `pdf_export_screen.dart` awaits the old controller's export, then reads status from the controller field, which `didUpdateWidget` may have replaced. The new controller is idle, not failed, so the dialog closes while the new export is starting. No test covers `didUpdateWidget`.

### Existing architecture decisions

Do not reopen the Markdown renderer, shared slide assembly, state-management approach, AI provider/model split, or persistence format as side effects of this work. Existing maintainer decisions already cover several of these areas.

## Corrections to the execution plan

### 1. Describe the method accurately

Call the earlier work a **source-reviewed architecture plan informed by `improve-codebase-architecture` and `codebase-design`; implementation and behavioral verification pending**.

Each claim should distinguish:
- inspected source;
- inferred consequence;
- executed check;
- proposed design.

Do not present this self-review as independent corroboration.

### 2. Do not make every proposed module mandatory

A deep module is justified when it removes real caller obligations and concentrates a behavior rule. A new class or file is not evidence of increased depth.

Names such as `ActiveDeckPublication` should remain proposed homes for proven ownership rules until the smallest correct implementation is known. For publication, the second pass found that the smallest correct implementation is the existing `DeckLibraryController`; a new class is not needed.

### 3. Remove soft scheduling dependencies

Several backlog dependencies describe a preferred order rather than a hard prerequisite. In particular:
- the saved-to-generated handoff regression need not wait for full memory replay work;
- refresh operation ownership can be fixed independently;
- stale PDF callbacks can be guarded in the current dialog before a session redesign;
- writer serialization can be tested and fixed inside the current writer;
- ADRs and domain terms should be written with the decision they record, not postponed until the end;
- obsolete coordination should be removed in the PR that proves its replacement.

### 4. Tighten acceptance tests

**Publication:** observe state during publication, not only after the overall future completes. A method that calls several existing setters is not automatically atomic.

**Replay:** test an update that occurs while a subscriber attaches. Also specify the behavior for valid deck A followed by an invalid update and then a new subscriber.

**Asset lifetime:** block a capture of an old revision, publish a replacement, run cleanup, then prove either that the old capture keeps its own asset view or that it is explicitly cancelled before saving. Verify eventual release.

### 5. Make merge gates scope-sensitive

Checks required for behavior changed by a PR must pass. A relevant blocked check remains an unverified guarantee unless the maintainer explicitly accepts a documented, limited exception.

Record exact command, tested SHA, host, result, and exclusions for each implemented change. Existing green CI is baseline evidence, not proof of newly proposed race scenarios.

### 6. Separate three work tracks

**Focused regressions and fixes**
- publication handoff, fixed inside the existing owner (`DeckLibraryController`), not in the widget lambda;
- reload completion and replay to late subscribers;
- refresh ownership;
- thumbnail/artwork identity (needs a recorded finding first);
- PDF cleanup and stale callbacks;
- writer exclusivity where supported calls justify it;
- delete the unread `DeckDocumentStore.revision`.

**Conditional structural changes**
- broader render-revision plumbing;
- private PDF capture host, or the single-use export run;
- one run-identity value across generation, Wizard, and application.

Choose these only when the focused fixes still leave material caller obligations. The neutral publication owner moved out of this track: it passes the deletion test today.

**Platform and release decisions**
- supported macOS/Xcode combination;
- export limits;
- interruption guarantees;
- DCM setup and debt work;
- distributed-client credential policy.

These require explicit maintainer decisions and should not silently expand into unrelated rewrites.

## Revised first milestone

1. Establish the pinned baseline.
2. Add the saved-A/failed-B regression and the smallest passing fix, inside `DeckLibraryController`.
3. Add the memory-reload terminal-result and late-subscriber regressions and the smallest passing fix.
4. Add PDF terminal-cleanup and stale-callback regressions and the smallest passing fixes.
5. Reassess whether enough coordination remains to justify the larger module shapes.
6. Record each structural decision alongside the change that implements it.

These slices can progress independently unless implementation evidence shows a real shared prerequisite.

## Structural artifact check

The supplied review artifacts were checked for internal structure:

- 36 work items;
- 9 proposed PR groups;
- 30 regression rows;
- 44 source-register entries;
- no duplicate task or regression IDs;
- no unknown task/regression/source/PR references in task records;
- no declared dependency cycles;
- no unassigned regression rows;
- three tasks (`SD-32`, `SD-33`, `SD-35`) with no regression IDs;
- no duplicate HTML element IDs or broken internal fragment links in the two checked HTML reports.

These checks do **not** prove test coverage, dependency necessity, runtime correctness, or that the proposed priorities are correct. The checked artifacts are not in the repository, so the counts cannot be re-run from it.

See `superdeck_architecture_audit_checks.json` for the machine-readable results.

## Evidence

- Matt Pocock, `improve-codebase-architecture`: https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/SKILL.md
- Matt Pocock, `codebase-design`: https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md
- SuperDeck repository guidance: `AGENTS.md`
- PDF public entry point: `packages/plugins/pdf/lib/superdeck_pdf.dart`
- PDF plugin: `packages/plugins/pdf/lib/src/pdf_plugin.dart`
- PDF controller: `packages/plugins/pdf/lib/src/pdf_controller.dart`
- PDF dialog: `packages/plugins/pdf/lib/src/pdf_export_screen.dart`
- Wizard handoff: `packages/playground/lib/features/ai/wizard/presentation/wizard_page.dart`
- Generated-result applier: `packages/playground/lib/features/ai/quick_agent/domain/generated_deck_result_applier.dart`
- Library controller: `packages/playground/lib/features/library/domain/deck_library_controller.dart`
- Document store: `packages/playground/lib/core/domain/stores/deck_document_store.dart`
- Memory loader: `packages/playground/lib/core/data/data_sources/memory_deck_loader.dart`
- App root providers: `packages/playground/lib/app/providers.dart`
- Runtime session state: `packages/superdeck/lib/src/deck/deck_session_state.dart`
- Retry entry point: `packages/superdeck/lib/src/deck/slide_page_content.dart`
- Recorded renderer/assembly decisions: `docs/maintainers/renderer-and-assembly-evaluation.md`
- Mermaid decision: `docs/maintainers/adr/0001-runtime-mermaid-rendering.md`

## Final disposition

The architecture direction survives the adversarial review. Blanket approval of the original 36-item execution plan does not. Apply the corrections above, require executed evidence for each behavior an implementation claims, and prefer the smallest change that removes a proven caller obligation. The second pass adds one change of stance: deck publication already has a proven owner, so fix it there first.
