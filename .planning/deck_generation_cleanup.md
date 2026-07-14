# Plan: Deck generation cleanup

> Stabilize the real generation workflow first, then make prompts, schemas,
> generated style, and UI handoff explicit and independently testable.

## Objective

- Primary outcome: a Generate Slides action that can be verified without the
  UI, produces a canonical SuperDeck document, opens that document for review,
  and applies the requested visual style.
- Out of scope: redesigning the conversational interview, adding image
  generation, or changing the deck-editing agent.
- Constraint: live Google AI tests must remain opt-in so normal tests and CI do
  not make networked or paid requests.

## Verified context

- The attached app run completed both generation phases for a 15-slide deck and
  loaded Markdown into `DeckDocumentStore`; the apparent failure was that
  `WizardPage` had no post-generation destination.
- `test_live/features/ai/quick_agent/generate_deck_smoke_test.dart` now exercises
  realistic `WizardContext` data through `buildPromptFromWizardContext`,
  `GenerateDeckCommand`, the live Google AI service, serialization, and Markdown
  parsing. Its first real run generated six valid slides with zero sanitizer
  removals in 18.9 seconds.
- `GenerateDeckCommand` now applies a validated `DeckGenerationResult.style`
  through `DeckCustomizationStore` before publishing the generated Markdown.
- The Wizard prompt contains user requirements only. Layout behavior lives in
  `deck_system.prompt` and its reusable `_deck_templates.prompt` partial.
- The structured schema now enforces the supported text-only subset: non-empty
  sections, blocks, and Markdown content; no widget or scrolling fields; and no
  runtime-only style/template registry references.
- The dormant examples loader and bundled examples were removed because they
  were never loaded and therefore never affected generation.
- Both generation phases use the existing Google client with the stable Gemini
  3.5 Flash model and thinking disabled for lower latency.

## Recommended approach

Keep the structured two-phase pipeline, but separate four contracts:

1. Wizard/user requirements: only topic, audience, content, count, and style
   choices.
2. Generation policy: one system prompt plus reusable layout templates.
3. Structured output: a generation-specific schema that enforces the supported
   text-only subset and still parses through the canonical `Slide` model.
4. Generated result: Markdown plus an explicit generated style payload that the
   host can preview or persist.

Do not enable the dormant full-deck examples by default. Structured output and
the layout templates already constrain shape, while adding all three examples
would substantially increase every final-deck request. Remove the dead path
after prompt-quality baselines exist; reintroduce a small example only if an
observed quality metric justifies it.

## Compatibility and migration

- The live smoke test and Wizard-to-present handoff are additive.
- Changing `GenerateDeckCommand` from a `void` result to a generated-deck result
  affects the Wizard summary card and the editor generation panel; migrate both
  in the same change.
- Narrowing the generation schema does not change SuperDeck's canonical slide
  contract. It only prevents this text-only generator from requesting reserved
  widget features.
- No persisted deck migration is required. Generated style remains in memory
  until a separate deck-file metadata format is deliberately designed.

## Work breakdown

- [x] Establish a live non-UI baseline.
  - Acceptance: real Wizard content produces the requested number of non-empty,
    parseable slides.
  - Verification: `fvm flutter test --dart-define-from-file=../../.env test_live/features/ai/quick_agent/generate_deck_smoke_test.dart`.

- [x] Repair the standalone UI handoff.
  - Scope: `wizard_page.dart`, `wizard_page_test.dart`.
  - Acceptance: new generated Markdown is sent through `MemoryDeckLoader` and
    opens `/present/0`; returning to the Wizard does not reopen unchanged output.

- [ ] Make generation output explicit.
  - Scope: `generate_deck_command.dart`, `deck_generator_service.dart`, summary
    card, editor generation panel.
  - Return a domain result containing Markdown, slide count, and generated style
    instead of reporting `void` after a hidden store mutation.
  - Preserve the existing editor behavior through an explicit result consumer.
  - Acceptance: command unit tests cover success, empty output, service failure,
    and missing API key without network calls.

- [x] Consolidate prompt ownership.
  - Scope: `prompt_builder.dart`, `deck_system.prompt`,
    `_deck_templates.prompt`, `deck_schemas.dart`.
  - Keep Wizard prompt output limited to user requirements. Keep behavioral and
    layout instructions in the system prompt/templates. Remove duplicated Dart
    guidance after prompt rendering tests pin the assembled prompt.
  - Acceptance: each generation rule has one source of truth and the live smoke
    test still returns the requested slide count with zero invalid slides.
  - Started: Wizard prompt output now contains only user requirements; its
    duplicate layout-guidance paragraph was removed and live generation remains
    green.

- [x] Align the structured schema with text-only generation.
  - Scope: generation schema in Playground plus the canonical AI projection in
    `packages/core/lib/src/deck/slide_contract.dart` only if a shared subset
    helper is needed.
  - Exclude widget-only fields and `scrollable` from this generator's response
    schema while retaining canonical parsing as the final gate.
  - Acceptance: schema tests prove unsupported block types cannot be emitted and
    valid generated slides still pass `Slide.parse`.

- [x] Apply generated style deliberately.
  - Scope: generated result model, `DeckCustomizationStore`, and Wizard result
    handoff.
  - Map validated colors/fonts into `DeckOptions` before opening present mode.
    Do not rely on generated `options.style` names that have no matching entry in
    `DeckOptions.styles`.
  - Acceptance: a widget test verifies generated background, heading/body colors,
    and font IDs reach the active `DeckController` options.

- [x] Remove dormant prompt machinery and improve observability.
  - Removed `ExamplesLoader` and `assets/ai_examples` after live quality
    baselines confirmed they were inactive and unnecessary.
  - Log phase, model, duration, candidate count, sanitized slide count, and a
    prompt/template revision identifier; never log the API key.
  - Acceptance: no unused prompt assets/loaders remain and failures identify the
    phase and structured-output reason.

## Test strategy

- Unit: prompt-builder contract tests under
  `test/features/ai/wizard/core/ai/services/`; command tests with an injected
  fake generation service; schema adapter and sanitizer tests under the existing
  Quick Agent test tree.
- Widget: Wizard generated-document handoff and generated-style application.
- Live: the opt-in six-slide smoke test. Keep the content and requested slide
  count stable so prompt/schema changes can be compared.
- Verification commands:
  - `fvm dart run build_runner build`
  - `fvm flutter test test/features/ai/wizard test/features/ai/quick_agent`
  - `fvm flutter analyze --fatal-infos`
  - `fvm flutter test --dart-define-from-file=../../.env test_live/features/ai/quick_agent/generate_deck_smoke_test.dart`

## Risks and stop conditions

- Generative output can vary. Structural assertions should be deterministic;
  wording and exact layouts should not be snapshot-tested.
- Prompt consolidation can change quality without breaking schema validation.
  Keep the live input fixed and compare slide validity, density, and latency.
- Stop a cleanup phase if the live smoke test fails twice for the same prompt or
  sanitizer removals increase; diagnose that boundary before continuing.
- Generated styles are currently ephemeral. Do not invent a persistence format
  as part of this cleanup; handle that in a separate deck metadata decision.

## Rollout

- Land in checkpoints: baseline/handoff, explicit result, prompt/schema cleanup,
  then style application.
- No feature flag is needed while this remains in the Playground branch.
- Each checkpoint can be reverted independently; retain the live smoke test as
  the release gate for later prompt or model changes.
