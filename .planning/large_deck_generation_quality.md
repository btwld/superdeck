# Plan: Large-deck generation quality and design variation

> Evolve the working outline-to-slide pipeline into a quality-controlled system
> that produces coherent, polished, visually varied 10–20-slide decks using
> described, versioned theme selection, end-to-end typography, custom-font
> support, and the same catalog pattern for deferred image-style selection.

Status: In progress; Tasks 1–6, the 12-theme runtime family, representative
render qualification, the deterministic ten-slide checkpoint, and the real
ten-slide narrative qualification are complete. Task 7 now uses the stable
Flash/Lite model split and concurrent section composition. Repeated real 15/20
visual qualification and the broader monorepo regression remain pending.

Checkpoint: `cf463294` (`feat: improve AI deck generation quality`), pushed to
`origin/leoafarias/iterative-ai-generation` on 2026-07-14.

Current handoff: [`ai_generation_session_status_2026_07_14.md`](ai_generation_session_status_2026_07_14.md)

## Verdict

**Refine, not rewrite.** Keep the plan-first pipeline and its inspectable
artifacts. Use one `gemini-3.5-flash` request for global narrative planning, then
compose the validated narrative sections concurrently with
`gemini-3.1-flash-lite`. Replace open-ended model-authored global style
tokens with selection from a curated, described, versioned theme catalog while
retaining per-slide composition/treatment decisions and explicit user brand
overrides. Reuse that catalog-selection contract for image style when image
generation returns. The current orchestration is a sound base; the current
prompts and validators are not yet a sufficient quality contract.

## Objective

- Primary outcome: a user can request a 10–20-slide deck and receive a coherent
  story with readable content, purposeful layout variation, a consistent but
  non-repetitive visual system, working tables/elements, and typography that is
  visibly appropriate to the selected direction.
- Customization outcome: one stable theme ID/version flows from Wizard/editor
  intent through the deck plan, generated slides, `DeckOptions`, captures, and
  later manual editing. Explicit user palette and font choices remain supported
  as validated overrides instead of reopening every theme token to the model.
- Selection outcome: the AI sees compact theme candidates containing an exact
  ID, display name, concrete selection description, and relevance tags. The
  runtime owns the complete palette, typography, spacing, component, and slide-
  treatment recipe. The deferred image-style flow follows the same split between
  selection metadata and a full runtime image treatment.
- Quality outcome: prompt/schema changes are evaluated with deterministic
  fixtures, exact structural/semantic checks, real rendered slides, contact
  sheets, and an opt-in visual-review rubric before they are accepted.
- Performance constraint: use `gemini-3.5-flash` for global planning and
  `gemini-3.1-flash-lite` for section composition and targeted repair. Keep the
  lowest supported thinking setting and do not add a production critic call
  until measurements show that its quality gain justifies the latency and cost.

## Task 7 generation policy: performance, context, and recovery

The first real 10/15/20 matrix proved that the plan-first architecture is worth
keeping, but the original acceptance policy is too broad and too expensive. A
10-slide success used 25 model requests instead of the ideal 11, a 20-slide
success used 50 instead of 21, and one 15-slide run exhausted outline repairs.
Every request used `thinkingBudget: 0`, the lowest setting supported by the
current client/model combination. The repeated calls came from deterministic
false positives and all-or-nothing retry behavior, not from model reasoning.

Latest real checkpoint (2026-07-15): `narrative_10` generated and rendered all
10 slides in 23.4 seconds using four provider calls (one Flash outline plus
three concurrent Flash-Lite sections), zero repairs, eight composition families,
and no repeated composition run. The machine-readable quality gate passed and
the contact sheet showed no visible overflow. Local artifact:
`packages/playground/test_live/ai_generation/artifacts/narrative_10_2026-07-15T01-15-32.776783Z/`.

Use three explicit validation tiers:

- **Hard contract:** schema/parseability, requested count and order, unique keys,
  section membership, exact selected theme and user overrides, grounded element
  source/name/cardinality, invented URLs/domains, renderer-safe structure, and
  concrete legal, compliance, credential, availability, security, or commercial
  claims. These may trigger one targeted repair; a deck-global failure can stop
  the run.
- **Repairable slide defect:** missing substantive content, broken Markdown or
  table structure, composition mismatch, invalid widget arguments, excessive
  density beyond twice the composition-aware budget, or a malformed heading
  hierarchy. Compose once and repair the current slide at most once. If it still
  fails, record that slide as failed and continue composing later slide slots.
- **Diagnostic quality signal:** unsupplied numbers, possible changes to a
  supplied number's meaning, design rhythm, composition diversity, broad
  editorial verbs, evidence-strength wording without a concrete high-risk claim,
  moderate density overages, and other heuristic quality observations. The
  prompt still asks the model to preserve supplied metrics, qualify new numbers
  as planned or illustrative, and respect density budgets, but a lexical or
  pacing heuristic does not prevent a renderable POC deck. Record these in traces
  and the quality report; never spend a production repair call on them.

Grounding applies to audience-facing plan fields (`title`, `assertion`, and
`contentUnits`) and final visible slide copy. Internal planning prose (`purpose`,
`contentBrief`, `continuity`, and section transitions) guides composition but is
not itself published evidence and must not create factual repair loops. A
grounded value may use its subject elsewhere on the same slide; labels such as
`31%` do not need to repeat a full source sentence in every block.

Do not silently skip a failed slide or discard already accepted slides. The
composition phase returns ordered per-slide outcomes. Later slides continue
using the validated plan and the most recent accepted slide as context. After
the pass, the caller receives the accepted slides plus exact failed slide keys,
typed issues, and retryability. The product UI keeps failed slots visible and
retryable; canonical deck persistence still requires every slot to resolve.

Performance budgets for the final matrix:

- Normal request path: one global outline plus one concurrent request per
  narrative section, normally three to five section requests for 10–20 slides.
- Accepted repair ceiling: at most one global outline repair followed by a small
  deck-wide budget of targeted slide-plan repairs. Generated section failures
  are returned per slide rather than restarting the deck.
- Target total requests: normally 4–6 before transport retries; any additional
  request must be visible in the artifact trace.
- Target repair rate: no more than 15% of slide requests across two samples.
- Initial outline prompt target: at most 10,000 characters; initial slide prompt
  target: at most 11,000. Each slide repair prompt must be smaller than its
  failed initial request. A deck-global outline repair may include the complete
  invalid plan, but uses dedicated compact instructions and runs at most once.
  These are regression budgets, not model token guarantees.
- Target pre-render generation time is 20 seconds, with 30 seconds as the normal
  maximum. Report provider latency separately from local capture.

Context is intentionally compact: the original typed request remains the user
message; the outline sees a concise planning contract and eligible theme
candidates; each section sees its ordered plan items, adjacent boundary plan
items, exact facts/elements, per-slide density budgets, and one deduplicated
canonical JSON shape example per composition used in that section. Dedicated
repair prompts contain the invalid current object, current blocking issues, and
only the guardrail snippets needed for those issue codes.

Compose narrative sections concurrently. The validated global blueprint and
adjacent boundary items preserve deck flow without serializing 10–20 provider
round trips. Preserve accepted slides when another slide or section fails.

Out of scope for the first quality pass:

- Arbitrary font-file upload, persistence, licensing, and redistribution. The
  first pass supports Google Fonts plus application-registered bundled custom
  families; uploaded `.ttf`/`.otf` files need a separate asset-lifecycle design.
- Automatic image synthesis or ungrounded image search. This plan defines the
  later image-style selection contract, but does not activate image generation
  in the first quality pass.
- A fully free-form canvas or model-authored Flutter styling code.
- Treating one model-generated aesthetic score as proof of quality. Rendered
  artifacts and deterministic invariants remain the release gate.

## Research basis

- Gemini recommends clear, direct, consistently delimited prompts, critical
  constraints near the start, context before the final task for long prompts,
  structured output for complex JSON, and iterative evaluation against observed
  responses. It also warns that too many examples can cause overfitting:
  [Gemini prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies).
- Gemini structured output constrains responses to syntactically valid JSON that
  follows the supported schema, but still requires application-level semantic
  validation:
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

The baseline findings below explain the completed Tasks 1–4 and the current
parameterized theme factory. Treat them as historical evidence, not a fresh
description of every file at the checkpoint. The later **Catalog selection gap**
section records the current theme/image-style delta, and the linked session
status is the operational handoff.

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

### Catalog selection gap

- `packages/playground/lib/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart`
  currently asks the outline model to emit a style name, direction, density,
  type scale, seven color roles, and two font families. The complete style object
  is then serialized into every single-slide prompt by
  `generation_prompt_provider.dart`. This repeats low-value choices and leaves
  palette/font validity to generation and repair.
- `packages/playground/lib/core/domain/design/generated_deck_theme_factory.dart`
  already provides the correct runtime ownership boundary: Dart maps semantic
  inputs into safe `DeckOptions` and named treatments. It is currently one
  parameterized factory, not a catalog of independently described, versioned
  theme recipes.
- `packages/playground/lib/features/ai/wizard/core/ai/prompts/image_style_prompts.dart`
  already separates an image style's ID, display title, short selection
  description, and full image-generation treatment. However,
  `deck_generation_request.dart` currently carries duplicated image-style name
  and description strings rather than the stable image-style ID retained in
  `WizardContext`.

## Approach tradeoffs

- Keep model-authored palette/font/style objects: rejected as the default because
  they repeat low-value tokens in every slide prompt and require repair for
  choices the renderer can guarantee.
- Use one or two hardcoded themes: rejected because consistency would come at the
  cost of meaningful deck-level variation.
- Send all roughly 30 full recipes to the model: rejected because it increases
  prompt size and exposes implementation details. Prefer compact described
  candidates, filtered without another model call; if the brief has no explicit
  direction, build a deterministic diverse shortlist across theme directions.
- Couple deck themes and image styles into combined presets: rejected because it
  creates a large theme-by-image-style matrix and makes both catalogs harder to
  evolve independently.

## Target experience

1. The Wizard or debug panel produces a typed generation brief with an exact
   slide count, audience, objective, content constraints, grounded elements, an
   optional exact theme, and explicit palette/typography overrides.
2. If the user did not select a theme, deterministic constraints filter the
   catalog to roughly three-to-five compatible candidates. The Flash model sees
   each candidate's exact ID, display name, short description, and tags, then
   selects one exact ID. It never receives or regenerates the full runtime recipe.
3. The Flash model returns one hierarchical deck blueprint: a story thesis,
   three-to-five acts/sections for a 10–20-slide deck, one exact selected theme
   ID, and an ordered visual rhythm with a concrete brief for each slide. The
   application resolves and records the catalog version.
4. Each narrative section is composed against its ordered slide briefs and the
   adjacent boundary briefs. The plan owns composition/treatment rhythm; compact
   canonical examples demonstrate only the layout families used by that section.
5. Model-facing structured output bounds arrays and uses the strongest supported
   types. Dart validates every returned slide independently against its plan,
   keeps valid slides, and exposes failed slots for targeted retry.
6. Dart resolves the selected theme into one coherent `DeckOptions` base style
   plus named treatments such as hero, section, content, data, quote, visual, and
   closing. The model selects semantic treatments; Dart owns font sizes,
   contrast, spacing, decoration, and safe renderer values.
7. The editor opens with the chosen palette and real font families applied. All
   levels remain manually editable after generation.
8. When image generation is reintroduced, image-style selection uses the same
   exact-ID flow. The AI sees compact descriptions; the image prompt builder
   resolves the full treatment from the catalog only after selection.
9. The live lab renders 10-, 15-, and 20-slide fixtures, produces a machine
   quality report and contact sheet, and optionally asks the same Flash model for
   a structured visual critique. Only deterministic failures block production.

## Proposed contracts

### Typed generation brief

Replace the lossy prompt-only handoff with a playground-owned request containing:

- raw user brief and exact `slideCount`;
- audience, purpose, tone, and required content when supplied by the Wizard;
- grounded image/QR/WebView/DartPad/custom-widget sources;
- an optional exact theme ID selected by the user; the catalog version is
  attached by the application after resolution;
- design direction and density preference;
- exact palette roles when selected;
- headline/body font IDs or family names selected from the typography catalog.

The free-text editor keeps working by wrapping text in the same request and using
an explicit count control/default. Do not infer a contractual count from prose
when the UI already knows it.

### Hierarchical deck blueprint

Keep an ordered flat slide list for simple sequential iteration, and add:

- `sections`: key, title, purpose, transition, slide keys;
- a versioned theme reference, resolved density, and an optional validated brand
  override containing only exact user-supplied palette/font constraints;
- per slide: section key, narrative role, assertion, content units, continuity,
  composition family, visual treatment, density, and grounded elements;
- a planned composition/treatment sequence that can be validated before slide
  composition begins.

The hierarchy organizes 10–20 slides without requiring a new runtime deck model;
it remains generation-only and normalizes to canonical `Slide` objects.

### Theme catalog and selection

Use one injectable theme catalog shared by Wizard previews, generation prompt
assembly, plan validation, runtime style resolution, the editor, live fixtures,
and artifact replay.

Each theme descriptor contains:

- a stable `id`, integer `version`, display `title`, and concise `description`;
- compact selection tags for visual direction, mood, audience/content affinity,
  light/dark mode, and supported density;
- a complete renderer-owned recipe: palette roles, typography pairing and type
  scale, spacing, shape/decorative language, component styling, and the seven
  named slide treatments;
- preview metadata used by Wizard/debug UI and screenshot fixtures.

The description is required. It is compact, concrete selection guidance that
states the theme's visual character, typography/layout behavior, and best-fit
content or audience; an ID or title alone is not enough to distinguish similar
systems. Prompt assembly exposes only the ID, title, description, and relevant
tags. Full tokens remain in Dart and are resolved only after selection.

An explicit user theme always wins. Otherwise, hard constraints first filter the
catalog to roughly three-to-five compatible candidates and the AI selects one
exact ID. A selection reason may be recorded in the debug trace, but is not part
of the persisted plan contract. Explicit palette or custom-font constraints
either narrow compatible themes or become a validated brand override on the
selected base theme; the model does not freely rewrite the remaining tokens.

Start with 10–12 meaningfully different, screenshot-tested themes and design the
catalog to grow toward roughly 30. Expansion requires a distinct typography,
composition, or component-treatment rationale and rendered evidence; palette-
only duplicates do not count as new themes.

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
- Unknown theme families or exact user overrides fail validation before slide
  composition; they never silently fall back while claiming success. With the
  theme catalog active, the model no longer invents font families.
- User-uploaded font files are deferred because they require storage, loading,
  licensing, and portability rules beyond prompt/schema work.

### Curated theme resolution

Keep model output semantic and bounded. Replace the current open-ended style
object with a selected `id`; the application resolves it and stores a theme
reference containing `id`, `version`, and the resolved deck density. Allow a
separate validated brand override only for exact user-supplied palette/font
constraints.

Dart resolves the theme recipe into safe `SlideStyler`s and the registered
`hero`, `section`, `content`, `data`, `quote`, `visual`, and `closing` treatments.
The model never emits raw Mix styling, arbitrary font sizes, font names, or color
tokens for every deck. Per-slide treatment and composition remain model-selected
so a shared theme does not make every slide structurally repetitive.

### Image-style catalog (deferred)

When image generation returns, promote the existing `ImageStyle` metadata into
an injectable, versioned catalog using the same selection contract as themes.
Each descriptor contains a stable ID/version, display title, required short
description, relevance/media tags, and the full renderer/image-prompt treatment.

The AI sees only compact candidates and returns an exact ID. The image-generation
service resolves the full treatment after selection. An explicit user choice
always wins. Theme and image style remain independent catalogs connected only by
optional compatibility tags; do not create a combinatorial theme-by-image-style
matrix. Replace duplicated `imageStyleName`/`imageStyleDescription` request fields
with the stable reference when this deferred phase is implemented.

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
- no accidental run of more than three identical compositions; treatments may
  repeat when the information shape and composition still vary meaningfully;
- 10/15/20-slide general-purpose fixtures use enough distinct purposeful
  composition families (target at least 5/6/7 unless the brief constrains them);
- body and heading colors meet 4.5:1 and 3:1 contrast respectively;
- selected fonts resolve and the actual capture uses the selected family;
- the selected theme ID/version resolves exactly, every catalog entry has a
  non-empty description, and the captured palette/fonts/treatments match the
  resolved recipe plus any explicit validated brand override;
- no heading-only content slide, unplanned widget, duplicate grounded element,
  Markdown replay mismatch, renderer exception, or detected overflow.

Rendered review rubric (reported, not initially production-blocking): narrative
flow, hierarchy, readability, visual balance, consistency, variation, typography,
table/data legibility, element relevance, and blank/overflow detection.

## Compatibility and migration

- Canonical `Slide`, Markdown, and widget payloads remain unchanged.
- The generation-only deck-plan and theme schemas may change directly; they are
  not persisted user contracts.
- Replace the generated style object with a theme reference in one branch-wide
  change. Update retained live fixtures/artifact readers deliberately; do not
  keep a long-lived dual style/theme contract.
- Keep current image-style request fields until the deferred image-generation
  phase begins, then replace them with the versioned reference in one change;
  do not add another compatibility layer now.
- Keep `GenerateDeckCommand` as the single Wizard/editor execution path, but
  migrate its argument from a bare string to the typed generation brief in one
  branch-wide change. There is no need for a long-lived compatibility shim.
- Existing manual customization remains available after selected-theme
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

- [x] Task 3: Add the hierarchical blueprint and typography catalog
  - Dependencies: Task 2.
  - Scope: `outline_schema.dart`, `deck_schemas.dart`, `font_styles.dart`, new
    colocated generation typography catalog files, outline prompt, style
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

- [x] Task 4: Make slide prompts composition-specific and history-aware
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

- [x] Task 5a: Land the described theme catalog and selection contract
  - Dependencies: Task 3; can proceed alongside Task 4 after catalogs stabilize.
  - Scope: the style/theme schema and serializer under
    `packages/playground/lib/features/ai/quick_agent/core/engine/`, a new
    colocated theme catalog/selector under
    `packages/playground/lib/core/domain/design/`, Wizard and generation-lab
    selection mapping, and focused schema/catalog/prompt tests.
  - Define stable ID/version/title/description/tag metadata and one compact
    model-facing projection. Add deterministic hard-constraint filtering and
    expose only three-to-five candidate descriptions when no explicit theme is
    selected.
  - Replace the plan's generated style object with a theme reference plus a
    validated explicit-user brand override. Resolve and attach the catalog
    version deterministically; unknown/stale IDs fail before slide composition.
  - Land three representative themes end to end first so selection, validation,
    artifact serialization, replay, and explicit-user precedence are proven
    before expanding the catalog.
  - Acceptance: descriptors have unique ID/version pairs and concrete non-empty
    selection descriptions; prompt snapshots contain only eligible compact
    candidates; explicit choices win; the model cannot submit a non-candidate
    ID; full palette/font/runtime recipes are absent from selection prompts; a
    brief without style constraints receives a deterministic shortlist spanning
    distinct directions without adding another provider call.
  - Verification: catalog/selector/schema/request round-trip tests, prompt
    snapshots, fake-outline selection tests, and retained-artifact replay.
  - Completed evidence: the shared injectable catalog contains three described,
    versioned representative recipes; local selection builds a deterministic
    compact shortlist without a provider call; the model-facing schema accepts
    only eligible IDs; Dart attaches and validates the canonical
    `{id, version, density, brandOverride?}` reference before composition; and
    Wizard, generation lab, runtime mapping, live artifacts, and retained
    artifact replay all resolve through the same catalog.
  - Final injection audit: `AiConversationProfile` owns the catalog instance and
    derives the Wizard prompt, `AskUserStyle`/`SummaryCard` model schemas and
    examples, parsing, selection context, and card rendering from it. A custom-
    ID regression proves no Wizard surface silently reverts to the default
    catalog, while unknown IDs still fail before rendering or generation.
  - Shortlist note: an unconstrained brief receives all three seed directions.
    Explicit choices return one candidate, and hard direction/brightness/density
    constraints may deliberately narrow below three rather than padding the
    shortlist with incompatible themes. Task 5b's 10–12-theme expansion gives
    constrained briefs enough compatible depth for the normal three-to-five
    range.
  - Verified on 2026-07-14: focused Task 5a contract tests (15), the broader
    theme/schema/Wizard/generation regression set (76), all workspace tests
    (694), workspace `analyze:all`, and `git diff --check` passed.

- [x] Task 5b: Expand and render-qualify the curated theme family
  - Dependencies: Task 5a.
  - Scope: `generated_deck_theme_factory.dart`,
    `deck_customization_store.dart`, customization sidebar, generation command/
    lab mapping, the theme catalog's runtime recipes, and widget/golden tests.
  - Preserve presentation-scale typography suitable for 1280×720 and named
    semantic slide treatments through `DeckOptions.styles`. Apply theme recipes
    to surfaces, accents, tables, code, quotes, links, and widget/element
    containers while preserving manual editing.
  - Resolve Google/registered custom fonts and required weights explicitly. Apply
    exact user palette/font overrides as a validated overlay and recheck contrast
    after resolution.
  - Grow the proven catalog from three to 10–12 materially distinct themes;
    expand toward roughly 30 only after each addition passes descriptor checks and
    rendered review.
  - Acceptance: at least three directions produce visibly different coherent
    contact sheets; exact custom registered families appear in resolved text
    styles; light/dark tables remain legible; every theme's render matches its
    description and no accepted entry is merely a palette duplicate.
  - Verification: store/theme/override unit tests plus representative golden and
    full-size/contact-sheet captures.
  - Completed evidence: the catalog contains 12 described recipes with distinct
    non-palette runtime signatures; all seven semantic treatments, surfaces,
    decorations, tables, code, quotes, links, built-in/custom widget containers,
    exact registered weights, and validated brand overlays resolve through one
    renderer-owned factory while manual edits retain the recipe. Focused coverage
    includes light/dark table contrast and all 12 font pairs. Editorial Midnight,
    Technical Paper, and Bold Product each render the deterministic ten-slide
    fixture at 1280×720 with actual declared fonts. Thirty full-size captures,
    three reviewed contact sheets, and three byte-stable opt-in golden baselines
    pass without generated header/footer chrome, title clipping, or uninitialized
    syntax highlighting. The render review also exposed dark-only syntax colors
    on Technical Paper's light code surface; SuperDeck now selects the syntax
    palette from the resolved code-container background and raises every token
    to at least 4.5:1 contrast. Light/dark widget regressions and a fresh
    30-slide golden qualification prove both paths.

- Checkpoint: run deterministic 10-slide generation with a fake model and inspect
  ordered section plans, resolved styles, and captured layout fixtures.
  - Completed evidence: `LIVE_FAKE_CHECKPOINT=true` performs one Flash outline
    request plus three Flash-Lite narrative-section requests with no repairs,
    verifies the exact model/thinking configuration, ordered section plans, and
    deduplicated canonical shape examples, serializes the canonical
    theme/plan/deck/prompts, records declared and loaded runtime font identities,
    replays ten Markdown slides, captures ten PNGs and a contact sheet, and passes
    the machine quality report with eight composition families and exact 10/10
    planned/generated/replayed/captured counts.

- [x] Task 6: Expand the live lab into a 10/15/20 quality harness
  - Dependencies: Tasks 1–4 for the foundational harness. Theme-specific matrix
    coverage is part of Task 7 and depends on Task 5b.
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
  - Dependencies: Tasks 5b and 6.
  - Run each large fixture at least twice to separate prompt defects from sampling
    variance. Review contact sheets, plans, prompts, responses, repairs, metrics,
    font rendering, and latency.
  - Change prompts/examples for recurring aesthetic/content failures; change
    schemas/validators only for real contractual failures.
  - Preserve the documented Flash/Lite split and lowest thinking setting. Record
    request count and wall time for 10/15/20 slides and reject changes that add
    unexplained calls.
  - Acceptance: all deterministic gates pass across the final large-deck matrix,
    no known blank/duplicate regression recurs, and human review confirms coherent
    story, readable hierarchy, useful variation, and visibly correct typography.
  - Verification: codegen, focused tests, full playground tests, workspace
    analysis/tests, `git diff --check`, and final live artifact matrix.
  - Current deterministic evidence: codegen passes; the focused AI/theme/Wizard
    suite passes 187 tests; `analyze:all` passes Dart, DCM, unused-file, and
    unused-code gates; the ten-slide fake checkpoint and 12-theme render
    qualification pass. The qualification includes the corrected light/dark
    syntax-token contrast and reviewed byte-stable baselines. The repeated real
    10/15/20 matrix and human review are still required before this task can
    close.

- [ ] Task 8: Introduce the deferred described image-style catalog
  - Dependencies: Task 7 and a separate decision to reactivate image generation.
  - Scope: `image_style_prompts.dart`, Wizard image-style cards/summary/context,
    `deck_generation_request.dart`, the future image-generation prompt builder,
    generation-lab fixtures, and focused tests.
  - Preserve the existing ID/title/description/treatment split, add explicit
    version and selection tags, and make one catalog the source of truth for UI,
    AI candidate descriptions, validation, and full prompt treatment resolution.
  - Replace duplicated image-style name/description request fields with the
    stable ID/version reference. Honor an explicit user choice; otherwise filter
    to a small compatible candidate set before AI selection.
  - Acceptance: every entry has a unique ID/version and non-empty description;
    candidate prompts omit full treatments; the selected exact ID deterministically
    resolves the full treatment; unknown/stale IDs fail before image generation;
    theme selection remains independent.
  - Verification: catalog/schema/request round-trip tests, Wizard selection tests,
    prompt snapshots, and opt-in image artifact comparisons when generation is
    actually restored.

## Test strategy

- Unit: schema adaptation bounds, typed request serialization, plan hierarchy,
  theme descriptor validation and candidate filtering, exact theme resolution,
  contrast, typography catalog resolution, composition contracts, element
  cardinality, density budgets, section shape examples, and theme factory. Add
  equivalent image-style catalog/request tests only in the deferred phase.
- Regression fixtures: commit the four known-bad model responses and prove they
  fail before repair; keep representative valid table/image/QR/WebView slides.
- Widget/golden: base typography scale, named treatment variants, light/dark
  table and quote styles, actual selected family, and custom registered family.
- Integration: fake-client 10/15/20 plan-to-section orchestration, repair isolation,
  exact count, cancellation, Markdown replay, and selected-theme application.
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
- Risk: a 30-theme catalog adds prompt noise and weak selections. Mitigation:
  filter deterministically to three-to-five eligible candidates and expose only
  compact names, descriptions, and tags.
- Risk: a small shortlist hides the best theme for an underspecified brief.
  Mitigation: make the fallback shortlist span distinct directions, evaluate
  selection quality across the live fixture matrix, and prefer all compact
  candidates over adding a separate selector model call if filtering performs
  worse.
- Risk: themes become shallow palette swaps. Mitigation: require a distinct
  typography, composition, or component-treatment rationale plus screenshot
  evidence before adding an entry.
- Risk: catalog descriptions drift from runtime output. Mitigation: keep
  selection metadata and the full recipe in one descriptor and test representative
  description-to-render expectations.
- Risk: theme and image-style options create a combinatorial matrix. Mitigation:
  keep catalogs independent, use optional compatibility tags only for filtering,
  and never encode every pair.
- Risk: visual review adds cost/latency without reliable signal. Mitigation: keep
  it opt-in and informational until repeated human/artifact comparisons calibrate
  thresholds.
- Risk: section concurrency weakens slide-to-slide continuity. Mitigation: keep
  one validated global blueprint, provide each section its adjacent boundary
  plan items, preserve exact ordered slide keys, and compare rendered contact
  sheets rather than relying on JSON success alone.
- Stop prompt tuning if a failure is caused by schema/sanitizer/rendering behavior;
  fix the contractual layer first.
- Stop schema expansion if the same outcome can be enforced more safely in Dart.
- Do not claim quality completion from JSON/test success alone; final contact
  sheets and actual typography must be reviewed.
