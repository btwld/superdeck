# SuperDeck architecture plan: adversarial audit

**Decision:** keep the main direction, but revise the execution plan before treating it as implementation-ready.

**Repository:** `conceptadev/superdeck`  
**Reviewed baseline:** `main@d160766c862a4ea7670a41c98f085bfae33a24f7`  
**Date:** 21 September 2026  
**Status:** source and plan audit; new application regressions were not executed.

## Context

This document is an adversarial second pass over the earlier SuperDeck architecture review, action plan, and backlog. It checks those artifacts against Matt Pocock's `improve-codebase-architecture` and `codebase-design` guidance, the repository's `AGENTS.md`, and selected implementation files.

It is a correction addendum. It does not turn the earlier 36-item backlog into 36 confirmed defects or mandatory architecture changes. The earlier work used the skills' source guidance and vocabulary, but did not execute the complete tool-driven process described by the skill, including an independent sub-agent exploration pass and the full candidate grilling loop.

## Findings that remain justified

### Active-deck publication

The Wizard releases the open saved deck before invoking the generated-result applier. That leaves a correctness-sensitive ownership rule in the caller. Keep the publication finding and add a regression for saved deck A followed by a failed or invalidated generated replacement B.

The desired invariant is: prepare a replacement completely, publish it only while it still owns the operation, and otherwise leave the previous deck coherent.

### Memory loader

`MemoryDeckLoader.reload()` is empty while runtime reload sets loading state to true. This is a direct contract mismatch. Fix it without inventing a generic event bus or changing every loader adapter.

Replay behavior needs stronger tests around the subscription handoff: no lost update, no duplicate replay to existing listeners, and no stale snapshot after a newer state.

### PDF lifecycle

Keep the focused PDF lifecycle work. The inspected export path has no terminal `finally` cleanup for captured PNG references and mutates shared run state before its `try` block.

However, narrow the architecture claim. The package's supported application-facing interface is already small: the public barrel exports the plugin and options, and the plugin opens the internal dialog. Application callers do not assemble the PageView, capture keys, and readiness scopes.

Therefore:
- keep focused cleanup, cancellation, and stale-callback fixes;
- treat a private capture-host extraction as conditional;
- do not add a public export-session abstraction merely to satisfy deep-module terminology.

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

Names such as `ActiveDeckPublication` should remain proposed homes for proven ownership rules until the smallest correct implementation is known.

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
- publication handoff;
- reload completion;
- refresh ownership;
- thumbnail/artwork identity;
- PDF cleanup and stale callbacks;
- writer exclusivity where supported calls justify it.

**Conditional structural changes**
- neutral publication owner;
- broader render-revision plumbing;
- private PDF capture host.

Choose these only when the focused fixes still leave material caller obligations.

**Platform and release decisions**
- supported macOS/Xcode combination;
- export limits;
- interruption guarantees;
- DCM setup and debt work;
- distributed-client credential policy.

These require explicit maintainer decisions and should not silently expand into unrelated rewrites.

## Revised first milestone

1. Establish the pinned baseline.
2. Add the saved-A/failed-B regression and the smallest passing fix.
3. Add the memory-reload terminal-result regression and the smallest passing fix.
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
- no duplicate HTML element IDs or broken internal fragment links in the two checked HTML reports.

These checks do **not** prove test coverage, dependency necessity, runtime correctness, or that the proposed priorities are correct.

See `superdeck_architecture_audit_checks.json` for the machine-readable results.

## Evidence

- Matt Pocock, `improve-codebase-architecture`: https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/SKILL.md
- Matt Pocock, `codebase-design`: https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md
- SuperDeck repository guidance: `AGENTS.md`
- PDF public entry point: `packages/plugins/pdf/lib/superdeck_pdf.dart`
- PDF plugin: `packages/plugins/pdf/lib/src/pdf_plugin.dart`
- PDF controller: `packages/plugins/pdf/lib/src/pdf_controller.dart`
- Wizard handoff: `packages/playground/lib/features/ai/wizard/presentation/wizard_page.dart`
- Document store: `packages/playground/lib/core/domain/stores/deck_document_store.dart`
- Memory loader: `packages/playground/lib/core/data/data_sources/memory_deck_loader.dart`
- Runtime session state: `packages/superdeck/lib/src/deck/deck_session_state.dart`
- Recorded renderer/assembly decisions: `docs/maintainers/renderer-and-assembly-evaluation.md`

## Final disposition

The architecture direction survives the adversarial review. Blanket approval of the original 36-item execution plan does not. Apply the corrections above, require executed evidence for each behavior an implementation claims, and prefer the smallest change that removes a proven caller obligation.
