# Plan: Large-deck generation quality and design variation

> Evolve the working outline-to-slide pipeline into a quality-controlled system
> that produces coherent, polished, visually varied 10–20-slide decks with
> end-to-end typography and custom-font support.

Status: Active

## Verdict

**Refine, not rewrite.** Keep the plan-first, one-slide-at-a-time Flash pipeline
and its inspectable artifacts. Add a hierarchical deck blueprint, a deterministic
design system, composition-aware semantic gates, and rendered quality evaluation.
The current orchestration is a sound base; the current prompts and validators are
not yet a sufficient quality contract.

## Objective

- Primary outcome: a user can request a 10–20-slide deck and receive a coherent
  story with readable content, purposeful layout variation, a consistent but
  non-repetitive visual system, working tables/elements, and typography that is
  visibly appropriate to the selected direction.
- Customization outcome: palette, design direction, typography scale, headline
  family, and body family flow from Wizard/editor intent through the deck plan,
  generated slides, `DeckOptions`, captures, and later manual editing.
- Quality outcome: prompt/schema changes are evaluated with deterministic
  fixtures, exact structural/semantic checks, real rendered slides, contact
  sheets, and an opt-in visual-review rubric before they are accepted.
- Performance constraint: retain the configured Flash model and keep explicit
  thinking disabled. Do not add a production critic call until measurements show
  that its quality gain justifies the latency and cost.

Out of scope for the first quality pass:

- Arbitrary font-file upload, persistence, licensing, and redistribution. The
  first pass supports Google Fonts plus application-registered bundled custom
  families; uploaded `.ttf`/`.otf` files need a separate asset-lifecycle design.
- Automatic image synthesis or ungrounded image search.
- A fully free-form canvas or model-authored Flutter styling code.
- Treating one model-generated aesthetic score as proof of quality. Rendered
  artifacts and deterministic invariants remain the release gate.

## Research basis

- Gemini recommends clear, direct, consistently delimited prompts, critical
  constraints near the start, context before the final task for long prompts,
  structured output for complex JSON, and iterative evaluation against observed
  responses. It also warns that too many examples can cause overfitting:
  [Gemini prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies).
- Gemini structured outputs support `minItems` and `maxItems`, and still require
  application-level semantic validation:
  [Gemini structured outputs](https://ai.google.dev/gemini-api/docs/structured-output?lang=rest).
- Recent presentation-generation work independently converges on hierarchical
  planning, separating page design from implementation, and reviewing rendered
  slides before regeneration:
  [DeepSlides](https://aclanthology.org/2026.findings-acl.1524/),
  [PreGenie](https://aclanthology.org/2025.findings-emnlp.165/), and
  [SlideSpace](https://www.microsoft.com/en-us/research/publication/slidespace-heuristic-design-hybrid-presentation-medium/).
- Microsoft presentation guidance emphasizes readable type at distance, concise
  text, meaningful graphics, consistent themes, and strong foreground/background
  contrast:
  [effective presentation guidance](https://support.microsoft.com/en-us/powerpoint/tips-for-creating-and-delivering-an-effective-presentation) and
  [professional layout guidance](https://support.microsoft.com/en-us/powerpoint/create-professional-slide-layouts-with-designer).
- Flutter supports declared `.ttf`, `.otf`, and `.ttc` custom fonts. The official
  `google_fonts` package supports lookup by family name, runtime fetching, cache,
  and asset bundling:
  [Flutter custom fonts](https://docs.flutter.dev/cookbook/design/fonts) and
  [`google_fonts`](https://pub.dev/packages/google_fonts).
- Generated palettes should enforce, at minimum, WCAG's 4.5:1 normal-text and
  3:1 large-text contrast thresholds:
  [WCAG 2.2 contrast](https://www.w3.org/TR/WCAG22/#contrast-minimum).

## Verified current context

### What to preserve

- `packages/playground/lib/features/ai/quick_agent/core/engine/services/deck_generator_pipeline.dart`
  generates a typed deck plan and then composes one slide at a time with previous
  slide and next-plan context. Invalid slides can be repaired without regenerating
  prior slides.
- `packages/playground/lib/features/ai/quick_agent/core/engine/prompts/generation_prompt_provider.dart`
  centralizes pure prompt assembly, making prompt snapshots and recorded live
  prompts possible.
- `packages/playground/test_live/ai_generation/ai_generation_smoke_test.dart`
  records the plan, each rendered prompt/response, canonical deck JSON, Markdown,
  traces, slide PNGs, and a contact sheet.
- `packages/playground/lib/core/domain/stores/deck_customization_store.dart`
  already applies a generated palette and font pair through one coherent
  `DeckOptions` update and derives table/code/blockquote styling from it.
- SuperDeck already exposes `SlideOptions.style`, deck-level named
  `SlideStyler`s, section rows, block columns, flex, spacing, tables, images,
  QR codes, WebViews, DartPad, and registered custom widget blocks.

### Correctness defects found in live artifacts

- The latest comparison artifact,
  `packages/playground/test_live/ai_generation/artifacts/comparison_table_2026-07-14T05-55-09.720946Z/`,
  passed validation even though slides 3 and 4 collapsed to heading-only slides.
  The raw response omitted required content from optional content-block fields;
  sanitization dropped the empty blocks and the validator accepted the remaining
  heading.
- The latest visual artifact,
  `packages/playground/test_live/ai_generation/artifacts/visual_elements_2026-07-14T05-50-45.689223Z/`,
  passed validation with ten WebViews on one planned one-WebView slide and three
  QR codes on one planned one-QR slide. Element source hydration is correct, but
  element cardinality and composition fulfillment are not validated.
- `packages/playground/lib/features/ai/quick_agent/core/engine/services/google_schema_adapter.dart`
  reports `minItems` and `maxItems` as unsupported even though the pinned Google
  API schema class exposes both fields. The model-facing schema therefore cannot
  bound sections or blocks.
- `packages/playground/lib/features/ai/quick_agent/core/engine/services/deck_plan_validator.dart`
  checks only empty/duplicate keys; it does not enforce the requested count,
  section rhythm, layout diversity, supported fonts, palette contrast, or element
  source/cardinality rules.
- `packages/playground/lib/features/ai/quick_agent/core/engine/services/generated_slide_validator.dart`
  proves canonical parseability and table syntax, not whether a slide fulfills
  its planned purpose, composition, content, or elements.

### Prompt and example defects

- `packages/playground/assets/ai_prompts/partials/_slide_examples.prompt`
  injects all four examples into every slide request. It includes unrelated fake
  image/QR/WebView sources and repeatedly demonstrates title-plus-body scaffolds,
  creating copying/overfitting pressure even when the current composition is text
  only.
- `packages/playground/lib/features/ai/wizard/core/ai/services/prompt_builder.dart`
  still tells generation to use two title/body sections for most slides and not
  to use widget blocks. That conflicts with the new capability-aware prompt and
  suppresses design variation requested by the user.
- `packages/playground/assets/ai_prompts/outline_system.prompt` has a useful flat
  slide plan but no acts/sections, design rhythm, density profile, or typography
  treatment for sustaining a 10–20-slide narrative.
- The slide prompt receives the entire plan and previous canonical slide, but no
  compact history of recent composition families or deliberate layout sequence.

### Design and typography defects

- `packages/playground/lib/features/ai/quick_agent/core/engine/prompts/font_styles.dart`
  exposes five headline and five body enums. The editor exposes a separate
  15-family list, so there is no single typography catalog or registered custom
  family path.
- `packages/playground/assets/ai_prompts/outline_system.prompt` says exact user
  fonts are honored, but `packages/playground/lib/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart`
  cannot represent a font outside those enums.
- `packages/playground/lib/core/domain/stores/deck_customization_store.dart`
  applies generated families to an undersized 40/32/24/20/18/16/18 logical-pixel
  type scale. SuperDeck's default 1280×720 style uses substantially larger display
  sizes; the contact sheets confirm that generated decks look small and sparse.
- The generated style contains only background, heading, body, and two font
  choices. It cannot express accent/surface roles, density, type scale, or named
  slide treatments, so structurally different slides still look like one global
  text theme.
- The live test loads Roboto bytes under every selected family name. It verifies
  plumbing but cannot prove the generated/custom font actually rendered.

## Target experience

1. The Wizard or debug panel produces a typed generation brief with an exact
   slide count, audience, objective, content constraints, grounded elements,
   design direction, palette preference, and typography overrides.
2. The Flash model returns one hierarchical deck blueprint: a story thesis,
   three-to-five acts/sections for a 10–20-slide deck, one shared design system,
   and an ordered visual rhythm with a concrete brief for each slide.
3. Each slide is composed against its current act, neighboring slide briefs, and
   a compact design ledger. The ledger records recent composition/treatment and
   prevents accidental repetition without forcing random layouts.
4. Model-facing structured output bounds arrays and uses the strongest supported
   types. A semantic validator checks the current slide against its plan before
   accepting it as context for the next slide.
5. The generated theme factory builds one coherent `DeckOptions` base style plus
   named treatments such as hero, section, content, data, quote, and closing.
   The model selects semantic treatments; Dart owns font sizes, contrast,
   spacing, decoration, and safe renderer values.
6. The editor opens with the chosen palette and real font families applied. All
   levels remain manually editable after generation.
7. The live lab renders 10-, 15-, and 20-slide fixtures, produces a machine
   quality report and contact sheet, and optionally asks the same Flash model for
   a structured visual critique. Only deterministic failures block production.

## Proposed contracts

### Typed generation brief

Replace the lossy prompt-only handoff with a playground-owned request containing:

- raw user brief and exact `slideCount`;
- audience, purpose, tone, and required content when supplied by the Wizard;
- grounded image/QR/WebView/DartPad/custom-widget sources;
- design direction and density preference;
- exact palette roles when selected;
- headline/body font IDs or family names selected from the typography catalog.

The free-text editor keeps working by wrapping text in the same request and using
an explicit count control/default. Do not infer a contractual count from prose
when the UI already knows it.

### Hierarchical deck blueprint

Keep an ordered flat slide list for simple sequential iteration, and add:

- `sections`: key, title, purpose, transition, slide keys;
- a design-system object containing palette roles, typography, density, and
  shape/accent direction;
- per slide: section key, narrative role, assertion, content units, continuity,
  composition family, visual treatment, density, and grounded elements;
- a planned composition/treatment sequence that can be validated before slide
  composition begins.

The hierarchy organizes 10–20 slides without requiring a new runtime deck model;
it remains generation-only and normalizes to canonical `Slide` objects.

### Typography catalog

Use one injectable catalog shared by Wizard preview, generation schema/prompt,
style application, editor controls, and live capture.

- Curated Google-font descriptors remain the default AI-selectable set. Expand
  it with intentional pairings and readable role metadata instead of exposing
  thousands of names to the model.
- An exact user-selected family is accepted when it resolves through
  `GoogleFonts.asMap()` or an application-registered custom descriptor.
- Registered custom descriptors contain a stable ID, display/family name,
  supported roles/weights, and whether the font is bundled or runtime-loaded.
- Unknown model-invented families fail plan validation and repair to a catalog
  family; they never silently fall back while claiming success.
- User-uploaded font files are deferred because they require storage, loading,
  licensing, and portability rules beyond prompt/schema work.

### Generated design system

Keep model output semantic and bounded. The generated design contract should
contain:

- color roles: background, surface, surface-alt, heading, body, accent, and
  accent-contrast;
- typography roles: headline/body family, display scale, weights, and density;
- visual direction: editorial, minimal, bold, technical, playful, or another
  registered descriptor;
- slide treatment names: hero, section, content, data, quote, visual, closing.

Dart maps those values into safe `SlideStyler`s. The model does not emit raw Mix
styling or arbitrary font sizes for every slide.

### Quality gates

Per-slide deterministic checks:

- raw and sanitized content cannot collapse a non-divider slide to only a title;
- planned composition is fulfilled (table contains a table, two/three-column has
  the expected dominant row, metric contains the planned numeric evidence);
- planned element names and counts match exactly; no unplanned or duplicate
  widgets;
- content blocks are non-empty, titles are unique/concise, tables are bounded,
  and visible text stays inside a density-specific budget;
- section/block counts, flex, insets, and spacing obey renderer-safe bounds.

Deck-level deterministic checks:

- generated, serialized, parsed, and captured slide counts equal the request;
- every plan key appears exactly once and every section has its planned slides;
- no accidental run of more than two identical composition/treatment families;
- 10/15/20-slide general-purpose fixtures use enough distinct purposeful
  composition families (target at least 5/6/7 unless the brief constrains them);
- body and heading colors meet 4.5:1 and 3:1 contrast respectively;
- selected fonts resolve and the actual capture uses the selected family;
- no heading-only content slide, unplanned widget, duplicate grounded element,
  Markdown replay mismatch, renderer exception, or detected overflow.

Rendered review rubric (reported, not initially production-blocking): narrative
flow, hierarchy, readability, visual balance, consistency, variation, typography,
table/data legibility, element relevance, and blank/overflow detection.

## Compatibility and migration

- Canonical `Slide`, Markdown, and widget payloads remain unchanged.
- The generation-only deck-plan and style schemas may change directly; they are
  not persisted user contracts.
- Keep `GenerateDeckCommand` as the single Wizard/editor execution path, but
  migrate its argument from a bare string to the typed generation brief in one
  branch-wide change. There is no need for a long-lived compatibility shim.
- Existing manual customization remains available after generated style
  application.
- Existing 5/6-slide live fixtures remain as fast smoke cases; add larger quality
  fixtures instead of replacing them.

## Work breakdown

- [x] Task 1: Close structural and semantic acceptance gaps
  - Scope: `packages/core/lib/src/deck/slide_contract.dart`,
    `packages/playground/lib/features/ai/quick_agent/core/engine/services/google_schema_adapter.dart`,
    `deck_plan_validator.dart`, `generated_slide_validator.dart`, and mirrored
    tests.
  - Forward supported `minItems`, `maxItems`, string bounds, and property order to
    Google's schema. Bound model-facing section/block arrays.
  - Validate the raw draft and sanitized canonical slide against the current plan
    slide, including composition fulfillment and exact element cardinality.
  - Acceptance: the recorded heading-only comparison responses and repeated
    WebView/QR responses fail with repairable, slide-specific errors.
  - Verification: `fvm flutter test test/features/ai/quick_agent/core/engine/services test/features/ai/quick_agent/core/engine/schemas --reporter expanded`.

- [x] Task 2: Establish one typed generation brief and remove prompt conflicts
  - Dependencies: Task 1.
  - Scope: `GenerateDeckCommand`, `DeckGeneratorService`, Wizard
    `prompt_builder.dart`/summary action, editor generation panel, generation lab,
    and their tests.
  - Carry exact slide count, grounded assets, design/font selections, and raw user
    intent as fields rather than re-parsing a prose contract.
  - Delete the legacy instruction that forbids widgets and mandates the same
    title/body layout for most slides.
  - Acceptance: the Wizard's selected 5–20 count, palette, families, and elements
    reach plan validation exactly; free text uses the same request type.
  - Verification: focused Wizard, command, prompt-builder, and generation-service
    tests.

- Checkpoint: replay the four known-bad raw responses through the new validator.
  No prompt tuning proceeds until all four fail for the intended reason and the
  existing valid fixtures still pass.

- [ ] Task 3: Add the hierarchical blueprint and design/typography catalogs
  - Dependencies: Task 2.
  - Scope: `outline_schema.dart`, `deck_schemas.dart`, `font_styles.dart`, new
    colocated generation design/typography catalog files, outline prompt, style
    serializer, generated Ack files, and tests.
  - Add sections/acts, assertion/content units, visual treatment, density, and a
    planned design rhythm while keeping the ordered flat slide list.
  - Replace disconnected font enums/lists with one catalog; allow exact known
    Google families and registered bundled custom families without permitting
    invented names.
  - Add accent/surface roles and semantic type-scale/direction settings. Validate
    palette contrast before composing slides.
  - Acceptance: deterministic 10-, 15-, and 20-slide plan fixtures validate exact
    counts, section membership, composition rhythm, contrast, and font resolution.
  - Verification: schema/codegen plus focused plan/catalog tests.

- [ ] Task 4: Make slide prompts composition-specific and history-aware
  - Dependencies: Task 3.
  - Scope: `slide_system.prompt`, `outline_system.prompt`, replace
    `_slide_examples.prompt` with validated composition-specific example assets,
    `generation_prompt_provider.dart`, prompt tests, and fixture tests.
  - Structure prompts as role/constraints, relevant context, one or two selected
    examples, then the final current-slide task.
  - Supply current section, neighbors, and a compact design ledger containing
    recent composition/treatment/density rather than encouraging blind rotation.
  - Inject widget examples only for the current grounded planned element and use
    its exact source. Never include unrelated fake URLs/assets.
  - Acceptance: every composition family has a canonical positive fixture that
    parses/renders; prompt snapshots contain only relevant examples and sources.
  - Verification: prompt snapshots, schema parity, sanitizer, validator, and
    renderer fixture tests.

- [ ] Task 5: Build a generated theme family with real typography
  - Dependencies: Task 3; can proceed alongside Task 4 after catalogs stabilize.
  - Scope: `packages/playground/lib/core/domain/stores/deck_customization_store.dart`,
    a colocated generated-theme factory, customization sidebar, generation
    command/lab mapping, and widget/golden tests.
  - Restore presentation-scale typography suitable for 1280×720, derive a
    coherent type scale from the selected direction/density, and expose named
    semantic slide treatments through `DeckOptions.styles`.
  - Apply the expanded palette to surfaces, accents, tables, code, quotes, links,
    and element containers while preserving manual editing.
  - Resolve Google/registered custom fonts explicitly and surface a precise error
    when a selected family is unavailable.
  - Acceptance: at least three design directions produce visibly different but
    coherent contact sheets; exact custom registered families are present in the
    resolved text styles; light/dark tables remain legible.
  - Verification: store/theme unit tests plus representative golden captures.

- Checkpoint: run deterministic 10-slide generation with a fake model and inspect
  the serialized design ledger, resolved styles, and captured layout fixtures.

- [ ] Task 6: Expand the live lab into a 10/15/20 quality harness
  - Dependencies: Tasks 1–5.
  - Scope: `packages/playground/test_live/ai_generation/`, generation lab presets,
    README, artifact metadata, and quality report helpers.
  - Add narrative 10, decision/data 15, and visual/product 20 fixtures plus
    typography variants using editorial, technical, and bold directions.
  - Produce a machine-readable JSON quality report with plan/slide/deck
    invariants, composition and
    treatment distribution, content density, palette contrast, element counts,
    resolved fonts, replay/capture counts, and timings.
  - Stop loading Roboto bytes under every family in live captures; load the actual
    Google or registered font and wait until it is ready before capture.
  - Add an opt-in Flash visual-review artifact that scores the contact sheet with
    the shared rubric. Keep it informational until correlated with human review.
  - Acceptance: one fixture or the full matrix can run without CI API spend and
    every failure points to a slide and rule.
  - Verification: documented live command with `LIVE_FIXTURE`/matrix selection.

- [ ] Task 7: Tune from rendered evidence and complete regression
  - Dependencies: Task 6.
  - Run each large fixture at least twice to separate prompt defects from sampling
    variance. Review contact sheets, plans, prompts, responses, repairs, metrics,
    font rendering, and latency.
  - Change prompts/examples for recurring aesthetic/content failures; change
    schemas/validators only for real contractual failures.
  - Preserve Flash and no explicit thinking. Record request count and wall time
    for 10/15/20 slides and reject changes that add unexplained calls.
  - Acceptance: all deterministic gates pass across the final large-deck matrix,
    no known blank/duplicate regression recurs, and human review confirms coherent
    story, readable hierarchy, useful variation, and visibly correct typography.
  - Verification: codegen, focused tests, full playground tests, workspace
    analysis/tests, `git diff --check`, and final live artifact matrix.

## Test strategy

- Unit: schema adaptation bounds, typed request serialization, plan hierarchy,
  contrast, typography catalog resolution, composition contracts, element
  cardinality, density budgets, design ledger, and theme factory.
- Regression fixtures: commit the four known-bad model responses and prove they
  fail before repair; keep representative valid table/image/QR/WebView slides.
- Widget/golden: base typography scale, named treatment variants, light/dark
  table and quote styles, actual selected family, and custom registered family.
- Integration: fake-client 10/15/20 plan-to-slide orchestration, repair isolation,
  exact count, cancellation, Markdown replay, and generated style application.
- Live: real Flash 10/15/20 runs save the complete artifact bundle, quality report,
  actual-font PNGs, and contact sheets. These remain opt-in and outside normal CI.
- Manual: review each contact sheet at full slide size and thumbnail size. Verify
  narrative rhythm, typography, tables, visual relevance, sparse/overfull slides,
  and transitions between sections.

Verification commands:

```bash
cd packages/playground
fvm flutter test test/features/ai/quick_agent --reporter expanded
fvm flutter test test/core/deck_customization_store_test.dart --reporter expanded

cd ../..
fvm dart run melos run build_runner:build --no-select
fvm dart run melos run analyze --no-select
fvm dart run melos run test --no-select

cd packages/playground
fvm flutter test test_live/ai_generation/ai_generation_smoke_test.dart \
  --dart-define-from-file=../../.env \
  --dart-define=LIVE_FIXTURE=large_deck_matrix \
  --reporter expanded
```

## Risks and stop conditions

- Risk: “variation” becomes randomness. Mitigation: plan an intentional sequence
  from content roles and validate it; do not ask each slide to choose independently.
- Risk: a richer schema becomes too complex for the API. Mitigation: keep the
  canonical slide unchanged, use small generation-only semantic contracts, and
  validate current Gemini schema support with focused adapter tests and one live
  probe before expanding it further.
- Verified deviation: Gemini accepts array bounds on the hierarchical outline
  schema, but a live schema-isolation probe showed that the complete nested
  single-slide schema is rejected as an invalid argument whenever array bounds
  are included. The slide request therefore omits only provider-side array
  bounds while raw/canonical Dart validation retains the exact 1–4 section and
  1–3 block limits. Property ordering, string bounds, and all simple-schema
  array bounds remain enabled.
- Risk: custom fonts silently fall back or fail offline. Mitigation: catalog
  resolution, explicit errors, actual-font live capture, and bundled-font support.
- Risk: visual review adds cost/latency without reliable signal. Mitigation: keep
  it opt-in and informational until repeated human/artifact comparisons calibrate
  thresholds.
- Risk: 20 sequential slide calls are slow. Mitigation: measure before changing
  orchestration, keep Flash/no-thinking, compact context, and avoid a mandatory
  second model pass. Consider bounded parallel composition only after the richer
  blueprint proves that generated-previous-slide context is not required.
- Stop prompt tuning if a failure is caused by schema/sanitizer/rendering behavior;
  fix the contractual layer first.
- Stop schema expansion if the same outcome can be enforced more safely in Dart.
- Do not claim quality completion from JSON/test success alone; final contact
  sheets and actual typography must be reviewed.
