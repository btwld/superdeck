# Plan: Iterative AI slide-generation pipeline

> Replace the monolithic final-deck request with a testable outline-to-slide
> composer that uses the existing Flash models, exposes SuperDeck's real layout
> capabilities, and produces inspectable JSON, Markdown, validation, and rendered
> artifacts for rapid quality iteration.

Status: Ready to execute

## Objective

- Generate a narrative outline first, then compose and validate each slide in
  sequence using the previous slide and the surrounding outline as continuity
  context.
- Support the layout surface that SuperDeck can render: multi-row sections,
  one-to-three-column compositions, flex, spacing, alignment, margin, padding,
  Markdown tables, images, QR codes, WebViews, DartPad, and registered custom
  widget blocks.
- Make prompt and output quality easy to iterate without completing the Wizard
  UI by adding a live smoke-test harness that preserves every intermediate
  artifact and rendered slide image.
- Keep `GenerateDeckCommand` as the shared Wizard/editor entry point and keep the
  canonical `Slide`/`WidgetBlock` payload backward-compatible.

Out of scope for the first implementation:

- Generating image pixels. The pipeline may compose `@image` blocks from a
  supplied/resolved source; image synthesis remains a separate service.
- Automatically enabling arbitrary custom widgets without an explicit schema
  and validator registration.
- Running paid live-model tests in normal CI.

## Verified context

### What works today

- `packages/core/lib/src/deck/slide_contract.dart` exposes the structured-output
  slide projection. It already includes sections, section spacing/alignment/flex,
  block alignment/flex, normalized margin/padding, scrolling, and the
  content/widget discriminator.
- `packages/core/lib/src/deck/block_model.dart` is the canonical runtime contract.
  `WidgetBlock` preserves non-reserved properties as widget arguments, so the
  final JSON format can already represent built-in and custom widgets.
- `packages/superdeck/lib/src/builtins/widgets.dart` always registers `image`,
  `dartpad`, `webview`, and `qrcode`.
- Markdown content already supports tables. Table styling is exposed by
  `packages/superdeck/lib/src/styling/components/markdown_table.dart`, with a
  default treatment in `packages/superdeck/lib/src/styling/default_style.dart`.
- `packages/superdeck/lib/src/capture/slide_capture_service.dart` can render a
  `SlideConfiguration` to PNG, so a quality harness does not need a second
  renderer.

### What constrains generation today

- `packages/playground/lib/features/ai/quick_agent/core/engine/services/deck_generator_service.dart`
  runs two model calls: one outline call and one whole-deck call. A malformed
  slide can invalidate the complete response, and no previous-slide context is
  available during composition.
- `packages/playground/lib/features/ai/quick_agent/core/engine/schemas/outline_schema.dart`
  limits layout hints to six text-oriented choices and has no table, image,
  embed, or richer narrative-role intent.
- `packages/playground/assets/ai_prompts/deck_system.prompt` explicitly forbids
  widget blocks, scrolling, and images even though the renderer supports them.
- `packages/core/lib/src/deck/slide_contract.dart` gives structured output only a
  widget name; it cannot describe widget-specific arguments such as image `src`
  or WebView `url`. Custom widget arguments therefore need an explicit
  generation catalog instead of an untyped arbitrary JSON map.
- `packages/playground/lib/features/ai/quick_agent/core/engine/prompts/examples_loader.dart`
  can load few-shot examples, but `DeckGeneratorService.generate` only loads the
  prompt registry. No production call currently loads those examples before
  formatting them.
- `packages/playground/lib/features/ai/quick_agent/domain/commands/generate_deck_command.dart`
  serializes generated slides but discards `DeckGenerationResult.style`.
  `packages/playground/lib/core/domain/stores/deck_customization_store.dart`
  explicitly has no AI-style application path, so the Wizard's selected palette
  and fonts do not reach the rendered deck.
- Current automated coverage validates schema adaptation and sanitization in
  `packages/playground/test/features/ai/quick_agent/`, but there is no real-model
  generation suite, prompt snapshot, per-slide orchestration test, or generated
  deck visual artifact.

## Recommended pipeline

```text
Wizard/free-text brief
        |
        v
Deck plan: theme + ordered slide briefs + composition intent
        |
        v
Slide 1 --validate/retry--> Slide 2 --validate/retry--> ... Slide N
   |       each request sees: deck plan, current brief, previous result,
   |       and next outline item
   v
Canonical List<Slide> + generated DeckStyle
        |
        +--> Markdown/editor
        +--> JSON + validation report
        +--> PNG captures/contact sheet
```

Use the existing Flash model constants in
`packages/playground/lib/features/ai/quick_agent/core/constants/gemini_models.dart`.
Keep model selection injectable so live fixtures can compare the existing
`gemini-2.5-flash` and `gemini-3-flash-preview` configurations without changing
pipeline code.

One slide per request is deliberately sequential for v1. It gives the composer
real continuity and isolates retries to a single slide. Parallel generation is a
possible later optimization only after quality measurements show that previous-
slide context is unnecessary for some slide classes.

## Contract decisions

1. Keep core's canonical `Slide`, `SectionBlock`, `ContentBlock`, and
   `WidgetBlock` unchanged.
2. Introduce a playground-owned structured-output draft contract for generation.
   It may represent widget data as a typed `{name, args}` draft and normalize it
   into the canonical flattened `WidgetBlock` payload before `Slide.parse`.
3. Add a generation element catalog. Each enabled element supplies its model
   schema, prompt guidance, canonical normalizer, and semantic validator.
4. Register built-ins first:
   - `image`: enabled when a source is provided or resolved; validate `src`, fit,
     finite positive dimensions/scale, and portability.
   - `qrcode`: enabled for explicit link/handoff intent; validate text, size,
     colors, and error correction.
   - `webview`: enabled only when the user supplies an HTTP(S) URL; never invent
     an arbitrary embed URL.
   - `dartpad`: enabled only when the user supplies a gist ID.
5. Let applications opt custom widgets into generation by registering a named
   descriptor. Unknown widget names fail validation instead of rendering a
   `Widget not found` placeholder.
6. Keep tables as Markdown content rather than creating a table widget. Add
   table-specific composition guidance and validation for consistent columns,
   bounded row count, and readable cell density.

## Work breakdown

- [ ] Task 1: Make model calls and prompts observable and testable
  - Scope: `packages/playground/lib/features/ai/quick_agent/core/engine/`
  - Introduce an injectable model-client boundary rather than constructing the
    Google service inside the orchestration method.
  - Split prompt construction into pure builders and load both `PromptRegistry`
    and `ExamplesLoader` deterministically before generation.
  - Add structured trace events for phase, model, elapsed time, attempt, slide
    index/count, rendered prompt, raw response, and validation result. Never log
    the API key.
  - Acceptance: a fake client can run the complete pipeline deterministically,
    and prompt text can be snapshot-tested without the network.
  - Verification: `fvm flutter test test/features/ai/quick_agent`

- [ ] Task 2: Replace the outline with a deck plan
  - Scope: `outline_schema.dart`, `outline_system.prompt`, generated schema files,
    and their tests.
  - Preserve `key`, `title`, and `purpose`; add narrative role, content brief,
    composition intent, and optional element requirements. Include explicit
    table, split-image, image-led, metric, quote, and embed intents without
    exposing raw Flutter layout details at the planning phase.
  - Generate the deck palette/fonts once in this phase so every slide shares one
    visual system.
  - Acceptance: the plan has the exact requested slide count, unique stable keys,
    a coherent opening/body/closing sequence, and enough intent to compose each
    slide independently.
  - Verification: schema/adapter tests plus fixture snapshots for three briefs.

- [ ] Task 3: Compose and retry one slide at a time
  - Scope: `deck_generator_service.dart`, `deck_generator_pipeline.dart`,
    `deck_generator_workflow.dart`, `generation_progress.dart`, and new
    slide-composer files colocated in the service domain.
  - For each slide, send the compact deck plan, current slide brief, previous
    canonical slide (or a bounded summary), and the next outline item.
  - Parse and validate immediately. Feed validation errors back to the same Flash
    model for a bounded repair retry, then stop with a precise slide-level error.
  - Preserve cancellation between calls. Report `Composing slide i of n` and
    `Repairing slide i of n` through progress instead of a single generic deck
    phase.
  - Acceptance: one invalid slide retries without regenerating prior slides, keys
    and order match the plan, and the final result contains exactly the planned
    count.
  - Verification: fake-client orchestration tests for ordering, continuity,
    cancellation, retry, and partial-failure behavior.

- Checkpoint: run the fake pipeline and inspect saved outline/per-slide prompts.
  Do not enable richer elements until basic sequential text/table decks are
  deterministic and valid.

- [ ] Task 4: Expose layouts, tables, and generation-capable elements
  - Scope: generation draft schemas/catalog, `deck_system.prompt`,
    `_deck_templates.prompt`, example fixtures, sanitizer/normalizer tests.
  - Teach composition about section rows, flex columns, spacing, alignment,
    normalized insets, fullscreen slides, Markdown tables, and the registered
    element catalog.
  - Replace blanket widget/image prohibitions with capability-aware rules.
  - Add positive few-shot examples for a readable comparison table, a text/image
    split, a QR handoff, and a supplied-URL WebView. Remove examples that teach
    repetitive title/body layouts as the only safe shape.
  - Acceptance: final normalized JSON parses through `Slide.parse`; widget args
    survive as canonical `WidgetBlock.args`; generated tables render as Markdown;
    no unsupported widget is emitted.
  - Verification: schema parity tests, normalizer tests, and renderer tests using
    static fixture payloads.

- [ ] Task 5: Apply generated visual style and make tables presentation-ready
  - Scope: `GenerateDeckCommand`, `DeckCustomizationStore`, provider wiring, and
    `test/core/deck_customization_store_test.dart`.
  - Add a typed **applyGeneratedStyle** method that maps the generated
    palette/fonts to the existing customization state and pushes one coherent
    `DeckOptions`.
  - Derive table header/body colors, border contrast, cell padding, blockquote,
    code, and link colors from the same palette rather than leaving white default
    component styles on every background.
  - Ensure manual customization continues to work after generation.
  - Acceptance: Wizard-selected colors/fonts affect the loaded deck, and a table
    remains legible on both light and dark generated backgrounds.
  - Verification: store unit tests and light/dark table widget captures.

- [ ] Task 6: Add a live generation lab and artifact bundle
  - Scope: a proposed **packages/playground/test_live/ai_generation/** folder, a
    debug-only playground route/surface, `.gitignore`, and
    `packages/playground/README.md`.
  - Keep live tests outside `test/` so `melos run test` never spends API quota.
  - Add three versioned prompts: narrative deck, comparison/table deck, and
    visual/element deck. Allow an individual fixture or all fixtures to run.
  - Save a run directory containing the user brief, deck plan, rendered prompt
    per slide, raw response per slide, canonical deck JSON, `slides.md`, validation
    report, timing/model metadata, PNG captures, and a contact sheet.
  - Reuse `SlideCaptureService` for captures. Static WebView/DartPad placeholders
    are expected in screenshots.
  - Add a debug-only in-app lab with the same three presets, per-slide progress,
    the generated thumbnail gallery, and expandable raw JSON/validation errors.
    The lab calls the production service; it must not duplicate generation logic.
  - Acceptance: one command produces a reviewable artifact directory, and the
    debug UI can reproduce the same fixture interactively.
  - Verification:

    ```bash
    fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
      --dart-define-from-file=../../.env --reporter expanded
    ```

- Checkpoint: review the three contact sheets and trace bundles. Tune prompts and
  examples using recorded failures; change schemas only when a failure is truly
  contractual rather than aesthetic.

- [ ] Task 7: Regression and cleanup pass
  - Remove the old whole-deck generation path, obsolete `generatingFinalDeck`
    state, stale text-only prompt rules, and dead helpers only after the new path
    is green.
  - Regenerate Ack outputs and update documentation to describe the actual
    outline-to-slide pipeline and live-test command.
  - Run focused tests, full playground tests, analysis, and one final live smoke
    bundle before merge.

## Test strategy

- Unit: draft schema adaptation, element catalog validation, canonical
  normalization, plan validation, table validation, per-slide prompt assembly,
  progress, retries, cancellation, and generated style application.
- Integration with a fake model: deterministic plan plus three slides; assert
  request order and that slide 2 sees slide 1 while slide 1 does not see future
  generated content.
- Renderer fixtures: table, two-row/two-column, image, QR, and WebView placeholder
  decks rendered with both light and dark generated styles.
- Live smoke: the three opt-in fixtures using the repository `.env`; inspect JSON,
  Markdown, validation, PNGs, and contact sheet. Record the model name in every
  artifact bundle so comparisons are meaningful.
- Commands:

  ```bash
  cd packages/playground
  fvm flutter test test/features/ai/quick_agent test/core/deck_customization_store_test.dart
  fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
    --dart-define-from-file=../../.env --reporter expanded
  cd ../..
  fvm dart run melos run analyze
  fvm dart run melos run test
  ```

## Quality gates

A live fixture passes structurally only when:

- The requested slide count and outline key order match exactly.
- Every response parses through the draft schema and then canonical `Slide.parse`.
- No slide is empty; no unsupported widget or invalid widget argument survives.
- Tables have consistent column counts and bounded density.
- Layout intent is not repeated mechanically across the deck.
- Every slide renders to PNG without an exception; contact-sheet inspection finds
  no visible clipping or overflow.
- The generated style is applied, and basic text/background contrast checks pass.

Visual quality is still a human-reviewed gate. The contact sheet is the primary
review surface; numeric heuristics should reject obviously broken decks, not claim
that a deck is aesthetically good.

## Alternatives considered

- Keep one whole-deck call: lower latency, but failures and retries remain
  deck-wide and per-slide continuity/layout control stays weak.
- Generate slides fully in parallel: faster, but each slide loses the preceding
  visual/narrative context requested for this workflow.
- Generate raw `slides.md`: simpler model output, but weaker structured
  validation and harder repair of one malformed slide.
- Put every possible widget argument directly in core's canonical AI projection:
  couples a Dart-only core contract to current built-ins and still cannot safely
  describe application-specific widgets.

## Compatibility and rollout

- No breaking change to compiled deck JSON or public SuperDeck rendering models.
- `GenerateDeckCommand(String prompt)` remains the Wizard/editor contract.
- Land sequential text/table composition first, then enable built-in elements
  through the catalog one at a time.
- Keep the existing whole-deck implementation only until the sequential path
  passes fake integration tests and all three live fixtures; then remove it in the
  same feature branch rather than carrying a permanent legacy path.
- Rollback is a single pipeline switch before legacy removal. After removal,
  revert the pipeline commit; no persisted-data migration is required.

## Risks and stop conditions

- More calls increase latency and quota use. Record per-phase latency/token-like
  response metrics, use Flash models, and cap repair retries.
- Passing full previous-slide JSON can grow prompts. Start with one previous slide
  plus the compact plan; add summarization only if traces show context pressure.
- Images and WebViews are nondeterministic in live rendering. Validate sources,
  use static placeholders during capture where appropriate, and never infer an
  arbitrary embed URL.
- Stop element expansion if the Google structured-output adapter cannot represent
  a descriptor without weakening validation. Keep that element disabled until a
  typed draft mapping exists.
- Stop prompt tuning when a failure is renderer/schema related; fix the contract
  or renderer fixture instead of adding contradictory prompt prose.
