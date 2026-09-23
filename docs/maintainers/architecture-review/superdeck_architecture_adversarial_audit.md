# SuperDeck architecture audit

> **Status:** The saved-deck library this audit examines is replaced by deck export in [#124](https://github.com/conceptadev/superdeck/pull/124). Its publication, saving, and ownership findings no longer apply. The memory-reload fix moved to #124, and the PDF terminal cleanup ships with this branch.

**Decision:** Investigate publication and saving first, then memory reload, then PDF terminal cleanup. Shared-module placement and late-subscriber replay stay open. This branch records those limits. It does not authorize a class merger.

**Repository:** `conceptadev/superdeck`  
**Reviewed code:** `882a3209491f7162880718c61889d6c1d1b156d1`  
**Code baseline:** `d160766c862a4ea7670a41c98f085bfae33a24f7` (the non-documentation tree of the reviewed commit)  
**Date:** 22 September 2026  
**Status:** Standalone source review. The regressions named below were not executed in Flutter.

## Standalone record

This Markdown file is the standalone record of the audit. The earlier architecture review, the action plan, and the backlog are not in the repository. A temporary candidate report was written outside the repository and is not available here either. That absence limits how far a reader can reconstruct the skill's presentation steps. This document does not claim that a missing temporary report proves every skill step ran.

What follows is checked against the source at the reviewed commit: callers, implementation, and existing tests. Flutter, the application, and the test runner were not run.

## Domain

Three decks are easy to treat as one object. They are not.

- A **generated result** is the `DeckGenerationResult` retained by `WizardGenerationController` after a generation attempt the controller kept. It holds that attempt's slides, artwork bytes, and theme.
- The **active runtime deck** is what the app is presenting: Markdown in `DeckDocumentStore`, slides in the deck session, theme in `DeckCustomizationStore`, and the artwork binding on `DeckLibraryAssetStore`.
- A **saved deck** is a named deck on disk, identified by `SavedDeckRef`: its Markdown file, its artwork files, and its theme manifest.

A correct save writes one of those as a single snapshot. A correct open or publication replaces the active runtime deck with one coherent deck. The defects below are places where those owners diverge.

The repository has no `CONTEXT.md`. These three names are the domain distinction this review needed. They are not a claim that a full glossary was produced.

## How terms are used

Module, interface, depth, seam, and locality follow the `codebase-design` glossary, with these applications:

- Depth is the leverage a caller gets, including ordering and failure behavior. A short list of method names in front of a long file is not a depth measurement.
- An interface is everything a caller must know. Leaving a declaration unchanged can still change observable behavior.
- A comment that describes current ownership, and a set of shared dependencies, record the current design. They do not by themselves choose the next home for a behavior.
- A function is a module. A helper-level test is not automatically the wrong seam. Removing one requires a replacement that still observes the guarantee.

## 1. Publication and saving

### Ordering defect, limited to result application

`WizardGenerationController`'s result callback calls `DeckLibraryController.releaseOpenDeck()` and then `GeneratedDeckResultApplier.apply()` (`wizard_page.dart` 119–126). `releaseOpenDeck()` clears the open saved deck, the last-save notice, and the artwork binding (`deck_library_controller.dart` 181–186). It runs before the applier can accept, abandon, or throw.

An ordinary planning or composition failure returns before that callback. `generateSlides()` checks cancellation, success or partial success, and non-empty slides, and only then calls `_completeComposition()` (`wizard_generation_controller.dart` 267–310). `_completeComposition()` is what enters the callback (`wizard_generation_controller.dart` 155–186). `retryFailedSlides()` uses the same completion path. The premature unbind is reached only when result application runs. From there the applier can reject the result, an asset write can fail, or `apply` can stop before publication. The applier does not restore the previous library binding.

Consequences, at the reviewed source:

- `releaseOpenDeck()` does not delete saved artwork files. It only forgets the binding.
- `DeckLibraryAssetStore.resolve()` consults the bound saved deck and otherwise the in-memory fallback (`deck_library_asset_store.dart` 34–42). Artwork still in memory can mask the missing binding.
- `ResolvedAssetImage` resolves again when its asset key or store changes (`resolved_asset_image.dart` 57–63). An image that already resolved can keep that URI. The store object itself stays stable across `bindTo`.
- Opening the saved deck again calls `open()`, which binds artwork once more. That is a later user operation. It is not rollback by the failed applier.

User-visible impact is therefore conditional. A same-run generated deck, or an image that already resolved, can conceal the defect. The regression that shows it uses a saved deck whose artwork exists **only on disk**, then a failed or abandoned application, then a fresh asset resolution.

### The deletion test does not choose a class

Deleting the applier would spread staging, sequencing, and cleanup into its caller. That is evidence that the applier is doing real work. It is not evidence that those responsibilities belong on `DeckLibraryController`.

Deleting the callback's `releaseOpenDeck()` call would stop the premature unbind. On a successful publication the previous saved-deck binding could remain active, so the old deck would still answer artwork lookups. That is a different failure from the failed-application case. The comparison shows an ordering obligation: change the saved-deck binding at an accepted publication point. It does not name a unique class to own that obligation.

`DeckLibraryController` currently combines library operations and runtime publication. Its class comment describes that current design. Adding generation-specific staging, result interpretation, cancellation, and eviction would couple library management to generation further. The comment is not a reason to do that.

Shared-module placement stays unresolved. Compare a small shared in-process publication operation with a prepared-deck operation on the existing controller. A new class is not required by the evidence. A new class is not forbidden by the evidence.

### Acceptance scenarios for one coherent deck

These three scenarios are the ownership contract. Moving the same setters into another class does not satisfy them.

**A saved result must not be mixed with another document.** `_WizardExperienceState._save()` takes images and theme from the retained `controller.result` (`wizard_page.dart` 161–182). `DeckLibraryController.save()` takes Markdown from the current global document (`deck_library_controller.dart` 102–123). Nothing checks that those inputs describe the same deck. The completed Wizard can push `/decks` (`wizard_page.dart` 249). The saved-decks button does the same while any stage is showing (`wizard_page.dart` 284–291). `open()` replaces the global document. The Wizard route stays under that push, so returning to it keeps the generated result. A save can then write deck B's Markdown with result A's artwork and theme. The storage writer persists the images it is given. It does not check that they match every reference in the Markdown.

Validation: generate A, open saved B, return to the Wizard, and save. The Markdown, artwork references, bytes, and theme must all belong to the deck the save action claims to save. This navigation path is established from the route and call structure. It was not executed in a running app.

**A newer saved-deck selection must survive an older generation.** The saved-decks button stays available during generation and does not cancel the Wizard operation (`wizard_page.dart` 284–291). The completion guard checks the Wizard operation epoch, cancellation, and disposal (`wizard_generation_controller.dart` 155–186). It does not check library selection or active-deck identity. Starting generation B, opening saved A, and then letting B finish can publish B over A.

Validation: hold generation at a deterministic gate, open A, release B, and assert that B does not silently replace A. Define what supersedes publication: either selecting another deck removes the earlier run's right to replace the runtime, or the result stays available for an explicit later acceptance.

**A malformed open must not mix the previous deck with the new one.** `open()` sets the open deck, binds artwork, and replaces Markdown before `updateMarkdown()` (`deck_library_controller.dart` 162–169). `MemoryDeckLoader.updateMarkdown()` catches a decode failure and emits an error (`memory_deck_loader.dart` 18–27). `open()` still returns success. When the session already has slides, `DeckSessionState` keeps those slides and records the error as a build failure (`deck_session_state.dart` 63–74). The visible slides can remain deck A's while the document and artwork binding are deck B's. This path does not need a generated result.

Validation: open valid A, attempt malformed B, and inspect the returned outcome together with the document, the artwork binding, the theme, and the visible slides. Failure must not leave a mixed deck. Last-good preview behavior has to keep the document identity, asset view, and theme that belong with those slides.

The ordering regression belongs on the same contract: after a saved deck is showing, a failed or abandoned application must leave that deck's document, artwork binding, and slides together, including when the artwork exists only on disk and is resolved again.

### `refresh()` busy guard, independent of publication

`save()` returns immediately when `_isBusy` is set (`deck_library_controller.dart` 107). `open()` does the same (`deck_library_controller.dart` 157). `refresh()` does not (`deck_library_controller.dart` 137–150), and it still sets and clears that flag. A refresh can overlap an open or a save, finish first, and mark the controller idle while the other operation is still running. A later operation can then start, and an older list or error can overwrite newer state.

Severity is medium. Confidence is high from the source. A guard, or explicit operation ownership, is a focused correction. It does not depend on moving generated publication into this controller. Test controlled completion ordering on its own.

### `DeckDocumentStore.revision` is unused, and it is the wrong identity

The counter and its getter remain at `deck_document_store.dart` 9–26. The comment says a long-running operation captures the value before publishing. The only reader in this tree is `deck_document_store_test.dart`. The publication path does not read it.

The counter is unused today. That does not mean publication needs no identity guard. The cross-deck cases above are the reason to settle identity before deleting anything. `replaceMarkdown()` also ignores identical text, so the counter would not move for two decks that share Markdown and differ in artwork or theme. Identical Markdown is not enough to identify those decks.

Remove the unused counter later, as its own cleanup, or replace it with the identity the operation actually needs. Do not prescribe automatic deletion from the lack of a reader, and do not infer safety from its absence.

### First implementation slice

Start with coherent active-deck publication and saving. The recommended first slice is those ownership guarantees, not a class merger. The first regressions are the three scenarios above, plus failed or abandoned application of a generated result. The aim is that a publish or a save names one deck and writes or shows only that deck.

Keep the generation pipeline, asset staging, the library persistence adapter, the renderer, and the PDF plugin interface unless one of those regressions requires a change. Fix memory reload on its own next. Address PDF terminal cleanup without treating controller replacement as the reason for a larger redesign.

## 2. Memory loader

### Retry reaches a reload that never finishes

`MemoryDeckLoader.updateMarkdown()` records the input before decoding. A decode failure emits `SlidesErrorEvent` (`memory_deck_loader.dart` 18–27). `load()` returns that broadcast stream. `reload()` returns immediately and emits nothing (`memory_deck_loader.dart` 31–34).

`DeckSessionState.reload()` clears the error, sets loading, and awaits the loader (`deck_session_state.dart` 78–87). `SlidePageContent` connects the fatal-error Retry action to `DeckController.reloadDeck()` (`slide_page_content.dart` 34–38), which calls that session reload. The empty future completes. The loading signal stays set until some other publication emits an event.

That path is reachable without an editor. `MacOsDeckLibrary.open()` reads saved Markdown as text and does not parse it (`mac_os_deck_library.dart` 409–428). `DeckLibraryController.open()` passes that text to the memory loader and returns success even when decoding emits an error. `SavedDecksPage._open()` then enters presentation (`saved_decks_page.dart` 33–38). `DeckPresenter` builds `SlidePageContent` (`deck_presenter.dart` 51–61) and does not bypass the error screen.

A malformed **first** saved deck can reach Retry, because fatal error requires that no slides have loaded (`deck_session_state.dart` 36–38 and 63–74). After a successful load, a later decode error is a build failure and the last slides stay. Severity is medium. Confidence is high from the call path.

### Required fix: reload completion

An explicit reload must produce a terminal result when the Markdown is unchanged, and it must define the no-input case, where no Markdown has been supplied. Ordinary `updateMarkdown()` deduplication can stay: identical text still does not need a new preview event on the update path.

Re-emitting the last error does not reread a corrected file from disk. Refreshing a saved deck that changed on disk remains a library-open concern.

### Late-subscriber replay is optional

The production app creates `DeckController` eagerly, before publication (`providers.dart` 17–23, `lazy: false` at 64–77). Replay could remove the "subscribe before the first event" obligation. It would also decide latest error versus last-good content, subscription handoff order, duplicate delivery, and what a new session observes after a valid deck followed by an invalid update. Those decisions need their own consumer and tests.

Replay is not required to fix the retry defect. It is not a decision this review treats as proved.

The eager-provider comment gives two reasons: the loader subscription, and seeding the initial `DeckOptions`. Replay addresses the subscription reason. It does not by itself remove eager `DeckOptions` seeding.

`BundledDeckLoader` and `FileDeckLoader` use their own controllers and reload cycles. A change confined to `MemoryDeckLoader` can leave them alone. The `DeckLoader` type promises `load()`, `reload()`, and `dispose()`. It does not promise replay or broadcast delivery. Imposing either on every loader would be a separate contract change.

## 3. PDF lifecycle

### Entry contract and terminal image release

`PdfController.export()` clears cancellation, counters, the error, the captured-image list, and status before `try` (`pdf_controller.dart` 264–271). That method has no guard against use after disposal or against overlapping exports. An explicit lifecycle contract is warranted: either the controller is single-use, or entry refuses reuse and overlap. Moving the assignments inside `try` does not by itself establish safe run ownership.

There is no `finally` that clears `_images`. A failure after some slides are captured, and before PDF assembly, retains those PNG references while the failure dialog stays open. `dispose()` does not clear the list either (`pdf_controller.dart` 363–375).

Successful assembly does clear the list. `_buildPdfForCurrentPlatform()` copies or transfers the images and then clears `_images` on both the web and native paths (`pdf_controller.dart` 334–347). Captured images are released on the success path. This is not an unbounded leak after the controller becomes unreachable.

The smallest fix is the entry contract above, plus releasing per-run image references on every terminal path, including failure and cancellation. The regression captures slide one, fails or cancels before the complete PDF is assembled, and checks that the controller no longer retains those bytes. Existing tests cover the normal handoff of images into PDF assembly and disposal during a pending save. Those guarantees stay.

### Controller replacement is a latent hazard

`_handleExport()` awaits `_exportController.export()` and then reads `_exportController` again (`pdf_export_screen.dart` 102–109). `didUpdateWidget()` disposes that controller and creates another when the widget's slide list changes (`pdf_export_screen.dart` 125–131). A caller that rebuilds the dialog with a different list could observe the new controller, which has not failed, and close the dialog while a new export is starting.

`PdfExportDialogScreen.show()` reads the slide list once (`pdf_export_screen.dart` 34–68). Both the shell-modal builder and the dialog builder close over that same list. Later deck updates do not pass a new list into the screen. The production plugin calls `show()` (`pdf_plugin.dart` 27–28). The supported invocation path does not produce the replacement. Treat the callback as a **latent replacement hazard**, not as a demonstrated application defect.

A local check that the completing controller is still the controller the callback started is small defensive work. Making the dialog explicitly snapshot-based, and removing replacement behavior the supported path does not use, is the other small option. Neither option requires a new public export-session module. The public plugin surface stays the plugin and its options.

### Testing hooks

`capturedImageCountForTesting` (`pdf_controller.dart` 101–102) is how tests see whether captured bytes are still held. The cleanup requirement above needs that observation, or an equivalent one. Do not delete this hook without a replacement retention check.

`waitForRenderBoundaryPaint` (`pdf_controller.dart` 136–138) is a different seam. Paint-wait tests that count fake context and render-object reads are coupled to the wait loop. Export-level waiting and timeout tests are a better observation of the same user-facing behavior. Replace that hook when the export-level tests exist. The presence of a larger export module is not a reason to drop either check first.

## 4. Generation engine

### Size at the reviewed tree

Physical line counts, including comments and blanks, for the files named here:

| File | Lines |
| --- | ---: |
| `deck_generator_service.dart` | 818 |
| `deck_generator_pipeline.dart` | 973 |
| `deck_generator_images.dart` | 285 |
| `deck_plan_repair.dart` | 246 |
| `deck_generator_workflow.dart` | 239 |
| **Total** | **2,561** |

A larger total would have to name more files. This review does not.

### What callers actually depend on

`plan`, `generateFromPlan`, `retryFailedSlides`, and `generate` are the four principal methods on `DeckGeneratorService`. Callers also depend on model choice, catalogs, budgets, timeouts, injected providers, partial-result semantics, and cancellation. Part files declare further public surface. Those obligations are part of the interface. Line count and the number of principal methods do not measure depth, and they do not justify a split.

`_withModelSession()` centralizes client setup and disposal. Generation hides schema preparation, provider requests, repair, and finalization. That work stays. The files being long is not a reason to split the engine.

### Approved-plan editing is worth exploring

`WizardGenerationController.updateSlide()` rebuilds a plan and calls `validateDeckPlanIssues()` with the typography, image-style, and theme catalogs taken from the generation service (`wizard_generation_controller.dart` 230–267). The Wizard therefore knows how to assemble the engine's validation context. Concentrating approved-plan editing and validation, so the caller does not repeat that catalog knowledge, is worth exploring. It is narrower than restructuring the engine or inventing a run-identity type for every operation.

Keeping the caller obligation is acceptable until that extraction has a concrete consumer. This review does not require it for the publication slice.

### Change history is not a hotspot ranking

`deck_generator_service.dart` changed on 18 July 2026, 7 September 2026, and 8 September 2026, among other dates. Those commits show continued work in the engine. This review did not define a history window, a path set, or a counting method, so it does not rank the engine as the hottest area. A keep decision for the pipeline does not need that ranking. The weak argument is using file size, or an undefined hotspot, as the reason to rewrite it.

## 5. Conditional size forecast

The figures below are a rough forecast of a **narrow** reading of each slice. They add as 250 + 120 + 80 = 450. That addition is not a measure of implementation effort, verification scope, or proof that a design is already the smallest correct one. The earlier estimate's eight source files and seven test files were not a locked file list. The test files were unnamed. They are not repeated here as scope.

| Slice | Forecast | Included | Excluded |
| --- | ---: | --- | --- |
| Publication | about 250 | A narrow change that moves the saved-deck binding to an accepted publication point, with a regression for failed application | Coherent snapshots, cross-publisher invalidation, and observation of publication during notifications. `WizardGenerationController` and the asset-store integration are outside the old four-file list and may be required by the scenarios in section 1 |
| Loader | about 120 | Reload completion, including unchanged Markdown and the no-input case, with tests | Late-subscriber replay. Folding replay into this number treats an optional contract change as part of the retry fix |
| PDF | about 80 | An entry guard, terminal release of per-run images, a local callback guard, and their regressions | A new run module, a public export-session type, and deletion of the captured-image hook |

A reasonable constraint is that these focused fixes do not require Dart type changes outside `packages/playground` and `packages/plugins/pdf`. Unchanged declarations are a different claim from an unchanged interface. Reload completion can stay inside `MemoryDeckLoader` while `DeckLoader`'s declarations stay as they are. Replay would change what a new subscriber observes even if those declarations stayed the same. The publication scenarios can require the Wizard controller to learn about the active deck without a new public type, and they can equally wait on a small shared operation. The forecast does not choose.

## 6. Left in place

This review does not reopen the Markdown renderer, shared slide assembly, the state-management approach, the AI provider and model split, or the persistence format. Those are settled: slide content stays on `flutter_markdown_plus`, both callers share `assembleSlides`, and Mermaid renders at runtime through `mermaid_core`.

The library persistence adapter, asset staging, and the PDF plugin's public barrel stay as they are unless a regression in sections 1–3 requires a change.

## Evidence

- Matt Pocock, `improve-codebase-architecture`: https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/SKILL.md
- Matt Pocock, `codebase-design`: https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md
- Repository guidance: `AGENTS.md`
- Wizard handoff and save: `packages/playground/lib/features/ai/wizard/presentation/wizard_page.dart`
- Wizard completion and outline edit: `packages/playground/lib/features/ai/wizard/presentation/wizard_generation_controller.dart`
- Generated-result applier: `packages/playground/lib/features/ai/generation/domain/generated_deck_result_applier.dart`
- Library controller: `packages/playground/lib/features/library/domain/deck_library_controller.dart`
- Saved-deck open page: `packages/playground/lib/features/library/presentation/saved_decks_page.dart`
- macOS library read: `packages/playground/lib/features/library/data/mac_os_deck_library.dart`
- Artwork binding: `packages/playground/lib/core/data/data_sources/deck_library_asset_store.dart`
- Document store: `packages/playground/lib/core/domain/stores/deck_document_store.dart`
- Memory loader: `packages/playground/lib/core/data/data_sources/memory_deck_loader.dart`
- App providers: `packages/playground/lib/app/providers.dart`
- Session state: `packages/superdeck/lib/src/deck/deck_session_state.dart`
- Retry screen: `packages/superdeck/lib/src/deck/slide_page_content.dart`
- Presenter: `packages/superdeck/lib/src/ui/deck_presenter.dart`
- Resolved images: `packages/superdeck/lib/src/ui/widgets/resolved_asset_image.dart`
- PDF plugin: `packages/plugins/pdf/lib/src/pdf_plugin.dart`
- PDF dialog: `packages/plugins/pdf/lib/src/pdf_export_screen.dart`
- PDF controller: `packages/plugins/pdf/lib/src/pdf_controller.dart`
- Generation service and parts: `packages/playground/lib/features/ai/generation/core/engine/services/`

## Disposition

Publication ordering is a real defect with a conditional user-visible effect, and the three cross-deck scenarios are the stronger reason to start there. The first code change should make a publish and a save refer to one deck. It should not start from a merger into `DeckLibraryController`.

Memory reload must finish, including when the input did not change and when there is no input. Replay waits for its own need. PDF export needs an entry contract and terminal release of captured images. The replacement callback stays a latent hazard of an unsupported rebuild. The generation engine stays intact. Approved-plan validation is the only engine extraction this review marks as worth exploring.
