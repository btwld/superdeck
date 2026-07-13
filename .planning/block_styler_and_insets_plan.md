# Plan: Constrained Block Styler and Insets Contract

> Replace the unrestricted block `BoxStyler` surface with a domain `BlockStyler`, add first-class block margin, standardize nested directive formatting, and remove contract/documentation drift without compatibility shims.

## Status

- Status: Ready for implementation
- Branch: `feat/predictable-layout-primitives`
- Related PR: `btwld/superdeck#99`
- Last updated: 2026-07-11

## Objective

- Replace `SlideStyler.blockContainer: BoxStyler?` with a constrained `BlockStyler?` that resolves to Mix `BoxSpec` but cannot add arbitrary widget modifiers.
- Keep layout ownership explicit: section `spacing` owns sibling gaps; block `margin` owns space inside an allocated block frame but outside its decoration; block `padding` owns space between decoration and content; block/section `align` owns content placement.
- Add `margin` beside `padding` to content and widget block directives, Dart models, validation, generated contracts, rendering, serializer round-tripping, docs, demo, and tests.
- Canonicalize nested directive maps so symmetric and physical edges are vertically readable inside nested braces.
- Resolve all known review gaps and remove duplicated schema/API/documentation paths so the branch has no intentional drift or deferred cleanup.

### Out of scope

- Serializing Flutter, Mix, `BoxSpec`, or `BlockStyler` objects into the Dart-only core contract.
- Exposing arbitrary per-block colors, borders, transforms, constraints, or modifiers in Markdown. Visual styling remains a Dart `SlideStyler` concern.
- Adding compatibility aliases, deprecated constructors, adapters from `BoxStyler`, or dual parsing modes for old unreleased branch output.
- Changing section spacing, flex allocation, or alignment precedence beyond making all consumers use the canonical contract.

## Verified context

- `packages/superdeck/lib/src/styling/components/slide.dart` accepts `BoxStyler? blockContainer` and resolves it to `StyleSpec<BoxSpec>`.
- `packages/superdeck/lib/src/rendering/blocks/block_widget.dart` resolves widget-block variants, calculates usable size from the resolved box, and currently patches only block padding after style resolution.
- `packages/superdeck/lib/src/utils/converters.dart` already accounts for resolved padding, margin, and border when calculating the child content rectangle.
- `packages/core/lib/src/deck/block_model.dart` owns block `align`, `flex`, `padding`, and `scrollable`; `WidgetBlock` reserves those keys from widget arguments.
- `packages/core/lib/src/deck/block_insets.dart` supports scalar, symmetric, and physical-edge authoring, but its schema/error vocabulary is padding-specific.
- `packages/core/lib/src/deck/slide_contract.dart` validates with the canonical schema and then decodes through generated mappers, bypassing authoring normalization.
- `packages/core/lib/src/markdown/tag_tokenizer.dart` supports balanced nested braces and parses their contents as YAML.
- `packages/builder/lib/src/parsers/slide_serializer.dart` currently flattens nested maps into one-line flow mappings.
- Parser probing confirmed multiline nested braces require commas between flow-map entries; ordinary nested block YAML also parses.
- `packages/playground/lib/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart` duplicates block, section, alignment, and flex schemas instead of consuming the core contract.
- Existing tests in `packages/superdeck/test/src/rendering/block_widget_test.dart` explicitly preserve a block-container modifier; that assertion must be removed under the new API.
- Known branch review gaps remain in image numeric normalization, compiled-contract inset normalization, Playground schema parity, overflow indicator placement, and authoring-reference parity.

Citation-check note: paths and symbols described as new or proposed do not exist yet by design. All cited existing repository paths were checked; the external `MixStyler` behavior was verified against the resolved Mix 2.1.0 source selected by `packages/superdeck/.dart_tool/package_config.json`.

## Design decision

### 1. Add `BlockStyler`, reuse `BoxSpec`

Create a public `BlockStyler` in a new `packages/superdeck/lib/src/styling/components/block_styler.dart` file. It extends `Style<BoxSpec>` directly rather than `MixStyler`, because Mix 2.1's `MixStyler` always includes `WidgetModifierStyleMixin`.

`BlockStyler` will expose this intentional surface:

- `padding` and `margin`, including Mix spacing convenience methods;
- `decoration` and `foregroundDecoration`, including color, gradient, border, radius, shadow, and image helpers;
- `clipBehavior`;
- context and `BlockVariant` variants;
- existing Mix animation metadata;
- merge, resolve, diagnostics, and equality behavior matching the repository's generated `SlideStyler` pattern.

It will not expose:

- `modifier`, `.wrap()`, or `WidgetModifierStyleMixin`;
- width, height, or arbitrary constraints;
- transform, scale, rotation, translation, or skew;
- box alignment, because `Block.align` and `SectionBlock.align` already own content placement;
- widget-state variants, because block containers are not an interaction control.

The resolved type remains `StyleSpec<BoxSpec>`, so the existing Mix `Box` renderer and interpolation path can be reused without a duplicate block spec or widget.

### 2. Keep serialized layout data separate from styling

`BlockStyler` is a Dart theme API. Markdown directive options remain platform-neutral core data:

```dart
Block {
  ContentAlignment? align;
  int flex;
  BlockInsets? margin;
  BlockInsets? padding;
  bool scrollable;
}
```

Use one `BlockInsets` implementation and one validation vocabulary for both fields. Parsing receives the field name so errors report `padding.left` or `margin.left` accurately.

Resolution precedence is fixed:

```text
default BlockStyler
-> deck/template SlideStyler merges
-> matching BlockVariant
-> per-block margin/padding overrides
-> rendered Mix Box
```

An absent block override retains the resolved style value. An explicit zero removes that inset. Per-block overrides replace only their matching inset and preserve decoration, foreground decoration, clipping, variants, and animation. `StyleSpec.widgetModifiers` must always be null for a block container resolved from `BlockStyler`.

### 3. Separate authoring input from normalized contracts

Avoid making one schema claim both shorthand authoring and normalized JSON behavior:

- `BlockInsets.authoringSchema` accepts a scalar, symmetric map, or physical-edge map.
- The compiled contract schema accepts only a closed, normalized physical-edge object with `top`, `right`, `bottom`, and `left`.
- Markdown parsing calls an explicit authoring parser that normalizes `padding` and `margin` before constructing blocks.
- `Slide.parse` and `parseSlidesContract` decode only normalized contract data.
- `SlideSerializer` always emits normalized physical edges.

This removes the current schema/decoder mismatch instead of adding another normalization patch.

### 4. Canonical nested directive formatting

Keep scalar shorthand compact:

```markdown
@block { padding: 16 }
```

Format nested symmetric maps vertically:

```markdown
@block {
  padding: {
    horizontal: 32,
    vertical: 16,
  }
}
```

Format normalized physical edges in clockwise order and put every edge on its own line:

```markdown
@block {
  padding: {
    top: 12,
    right: 24,
    bottom: 12,
    left: 24,
  }
  margin: {
    top: 8,
    right: 12,
    bottom: 8,
    left: 12,
  }
}
```

The commas are required because the inner braces are YAML flow mappings. The tokenizer will continue accepting ordinary nested block YAML, but serializer output and all maintained examples use the canonical brace format above.

### 5. Define spacing versus margin explicitly

```text
section spacing
  [allocated block frame
    margin
      decoration and border
        padding
          content
  ]
```

- `spacing` is the shared gap between sibling block frames and affects horizontal allocation.
- `margin` is consumed inside one block's allocated frame and reduces its usable/decorated area; it does not alter flex ratios or create a shared gutter.
- `padding` is consumed inside the decorated block container and reduces the content rectangle.

### Alternatives rejected

- Keep `BoxStyler` and document "do not use modifiers": rejected because the public type still permits geometry-changing wrappers and cannot enforce the contract.
- Accept `BoxStyler` and strip or reject modifiers at runtime: rejected because invalid configuration remains representable and failures move from compile time to runtime.
- Copy every `BoxStyler` field except modifiers: rejected because constraints, transforms, and box alignment create competing geometry owners even without wrappers.
- Add a new `BlockContainerSpec` and widget: rejected because the selected fields already map cleanly to `BoxSpec`; a second spec would duplicate Mix rendering and interpolation logic.
- Keep separate Playground schemas and add parity tests only: rejected because tests detect drift after it happens; deriving the AI slide schema from core prevents it.

## Compatibility and migration

- This is an intentional hard break. `SlideStyler.blockContainer` changes from `BoxStyler?` to `BlockStyler?`.
- Replace every in-repository `blockContainer: BoxStyler(...)` with `blockContainer: BlockStyler(...)`.
- Remove block-container modifier examples and tests. Callers needing arbitrary wrappers must own them in custom widget implementations or slide parts, not the framework-owned block frame.
- Add no aliases, deprecated overloads, conversion factories, or escape hatches.
- Generated deck contracts must be rebuilt after adding `margin` or changing normalized inset schema shape.
- No persisted data migration is required. Rollback is a source revert followed by code generation, schema export, and demo contract rebuild.

## Cross-cutting constraints

- Performance: resolve and patch one `BoxSpec` per block without intrinsic measurement, extra layout passes, or duplicate widget builds.
- Accessibility and internationalization: no semantics, focus, reading-order, or localized-string contract changes are introduced.
- Security and privacy: not applicable; this change processes local presentation layout/style data and adds no new trust boundary or data flow.
- Observability: retain the debug overflow log's slide key, block key, measured/available size, and overflow axes while making its visual marker non-obscuring.
- Rollout: no feature flag or staged dual path. Land the hard API/contract cut atomically with generated artifacts, docs, and tests.

## Work breakdown

- [ ] Task 1: Make block insets generic and define normalized contracts
  - Dependencies: None
  - Scope: M
  - Files: `packages/core/lib/src/deck/block_insets.dart`, `packages/core/lib/src/deck/block_model.dart`, `packages/core/lib/src/deck/slide_contract.dart`, generated `*.mapper.dart`, `packages/core/schema/superdeck.slides.schema.json`, `packages/core/lib/superdeck_core.dart` if exports change.
  - Work:
    - Split authoring and normalized inset schemas.
    - Generalize error messages and parsing for both `padding` and `margin`.
    - Add nullable `margin` to `Block`, `ContentBlock`, and `WidgetBlock`; reserve it from widget args.
    - Add explicit authoring parse entry points and keep compiled-contract parsing normalized-only.
    - Make `parseSlidesContract` use the normalized contract decoder instead of bypassing invariants.
    - Regenerate mappers and the exported JSON schema; remove superseded helpers rather than retaining duplicate paths.
  - Acceptance:
    - Scalar/symmetric/physical authoring normalizes for both fields.
    - Contracts contain four physical edges and reject authoring shorthand.
    - Invalid values report the correct field and edge.
    - `padding: null`/`margin: null` means inherit; explicit zero remains representable.
  - Verification: `cd packages/core && fvm dart test test/src/deck/block_model_test.dart test/src/deck/slide_contract_test.dart test/public_api_test.dart`

- [ ] Task 2: Canonicalize nested directive parsing and serialization
  - Dependencies: Task 1
  - Scope: M
  - Files: `packages/core/lib/src/markdown/tag_tokenizer.dart`, `packages/core/test/src/markdown/tag_tokenizer_test.dart`, `packages/builder/lib/src/parsers/section_parser.dart`, `packages/builder/lib/src/parsers/slide_serializer.dart`, parser tests under `packages/builder/test/src/parsers/`.
  - Work:
    - Route block directives through the explicit authoring parser.
    - Replace `_yamlValue`'s one-line map formatting with one recursive directive formatter for scalars, lists, nested maps, indentation, commas, and quoting.
    - Emit scalar-only directives inline; emit nested maps in canonical multiline braces.
    - Add exact-output and parse/serialize/parse idempotency tests for symmetric padding, physical padding, margin, nested widget args, lists, and quoted braces.
    - Add a negative test explaining that multiline flow maps without commas are invalid YAML.
  - Acceptance:
    - The canonical examples in this plan parse exactly.
    - Serializer output is stable on a second serialization.
    - Arbitrary widget argument maps are not corrupted by the new formatter.
  - Verification: `cd packages/builder && fvm dart test test/src/parsers/block_parser_test.dart test/src/parsers/section_parser_test.dart test/src/parsers/slide_serializer_test.dart`

- Checkpoint 1: regenerate core mappers and schemas, then run `fvm flutter pub run melos run contracts:check --no-select`; do not begin the style migration while core/parser tests or schema checks fail.

- [ ] Task 3: Introduce the modifier-free `BlockStyler` API
  - Dependencies: Checkpoint 1
  - Scope: M
  - New files: `packages/superdeck/lib/src/styling/components/block_styler.dart`, `packages/superdeck/test/src/styling/components/block_styler_test.dart`.
  - Files: `packages/superdeck/lib/src/styling/components/slide.dart`, `packages/superdeck/lib/src/styling/default_style.dart`, `packages/superdeck/lib/superdeck.dart`.
  - Work:
    - Implement `BlockStyler extends Style<BoxSpec>` manually, following `SlideStyler` merge/resolve/diagnostic conventions.
    - Support spacing and decoration convenience APIs, clipping, variants, and animation while hardcoding `modifier: null`.
    - Change `SlideStyler`'s public `blockContainer` constructor parameter to `BlockStyler?` while retaining the resolved `StyleSpec<BoxSpec>` field.
    - Convert default image/gist/webview `BlockVariant` rules to `BlockStyler`.
    - Export only the intended public style type; do not expose a compatibility adapter.
  - Acceptance:
    - Base and variant styles merge and resolve to the expected `BoxSpec`.
    - `StyleSpec.widgetModifiers` is always null.
    - The type exposes no modifier, constraints, transform, or box-alignment API.
    - Existing default block padding/margin/decoration behavior is expressible.
  - Verification: `cd packages/superdeck && fvm flutter test test/src/styling/components/block_styler_test.dart test/src/styling/block_variant_test.dart`

- [ ] Task 4: Apply margin and padding through one render path
  - Dependencies: Task 3
  - Scope: M
  - Files: `packages/superdeck/lib/src/rendering/blocks/block_widget.dart`, `packages/superdeck/lib/src/utils/converters.dart`, `packages/superdeck/test/src/rendering/block_widget_test.dart`, `packages/superdeck/test/src/rendering/section_widget_test.dart`, `packages/superdeck/test/src/utils/converters_test.dart`.
  - Work:
    - Consolidate block inset application into one helper that patches resolved margin and padding only when present.
    - Preserve decoration, foreground decoration, clipping, variants, and animation; remove all modifier-preservation code and assertions.
    - Verify usable-size calculations count style or block margin/padding and border exactly once.
    - Cover absent, zero, symmetric, asymmetric, style-default, `BlockVariant`, content-block, widget-block, and spacing-plus-margin cases.
  - Acceptance:
    - Margin and padding overrides apply after matching variants.
    - Margin reduces only its own allocated frame; section spacing and flex ratios remain unchanged.
    - No modifier can wrap the framework-owned block container.
  - Verification: `cd packages/superdeck && fvm flutter test test/src/rendering/block_widget_test.dart test/src/rendering/section_widget_test.dart test/src/utils/converters_test.dart`

- Checkpoint 2: run targeted core, builder, and superdeck suites together. Stop if any path decodes shorthand differently, applies insets twice, or resolves a block modifier.

- [ ] Task 5: Remove Playground schema duplication and preserve canonical layout fields
  - Dependencies: Checkpoint 2
  - Scope: M
  - Files: `packages/playground/lib/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart`, generated `deck_schemas.g.dart`, `deck_generator_pipeline_helpers.dart`, `deck_generator_workflow.dart`, and mirrored tests under `packages/playground/test/features/ai/quick_agent/core/engine/`.
  - Work:
    - Build the AI slide portion of `slideGenerationSchema` from the exported core `Slide.schema` instead of local block/section/alignment/flex copies.
    - Remove unused generated `SlideBlockType`, `SlideSectionType`, `SlideType`, and `CreateSlideType` surfaces if no caller remains.
    - Keep only Playground-owned style schema and prompt guidance.
    - Ensure sanitization preserves valid `spacing`, `padding`, and `margin`, then feeds normalized data through the canonical slide parser.
    - Add adapter/schema tests proving positive flex, section-only spacing, block padding/margin, and reserved widget fields match core.
  - Acceptance:
    - No copied alignment list or block/section layout schema remains in Playground.
    - A schema change in core automatically reaches AI generation.
    - Invalid generated layout data fails with the canonical error instead of a later mapper error.
  - Verification: `cd packages/playground && fvm flutter test test/features/ai/quick_agent/core/engine`
  - Stop condition: if the Google schema adapter cannot consume the canonical discriminated schema, add one shared AI-compatible schema factory in `superdeck_core`; do not restore a Playground-owned copy.

- [ ] Task 6: Close the remaining implementation review gaps
  - Dependencies: Checkpoint 2; safe to run in parallel with Task 5 after shared contract work is stable.
  - Scope: S
  - Files: `packages/superdeck/lib/src/builtins/image_widget.dart`, `packages/superdeck/test/src/builtins/image_widget_test.dart`, `packages/superdeck/lib/src/ui/widgets/overflow_clip.dart`, `packages/superdeck/test/src/rendering/block_widget_test.dart`, relevant golden test files.
  - Work:
    - Accept and normalize both integer and double values for image `width`, `height`, and `scale` with one finite-positive numeric rule.
    - Replace the filled top-right overflow square with a non-obscuring frame indicator and retain deduplicated size/axis logs.
    - Add regression tests for integer image authoring and top-right-aligned overflow content.
  - Acceptance:
    - Demo image values such as `width: 300`, `height: 300`, and `scale: 1` parse successfully.
    - Debug overflow remains visible without covering the aligned content corner.
  - Verification: `cd packages/superdeck && fvm flutter test test/src/builtins/image_widget_test.dart test/src/rendering/block_widget_test.dart`

- [ ] Task 7: Update every maintained example, guide, demo, and generated artifact
  - Dependencies: Tasks 4, 5, and 6
  - Scope: M
  - Files: `demo/slides.md`, `demo/lib/src/style.dart`, `demo/lib/src/templates.dart`, `demo/.superdeck/`, package changelogs, `docs/guides/markdown-authoring.mdx`, `docs/guides/superdeck-overview.mdx`, `docs/reference/block-types.mdx`, `docs/reference/contracts.mdx`, `docs/reference/deck-options.mdx`, `docs/reference/markdown-syntax.mdx`, `docs/tutorials/block-layouts.mdx`, and `.agents/skills/superdeck-presentations/` references.
  - Work:
    - Replace block-container `BoxStyler` examples with `BlockStyler` and remove modifier-preservation claims.
    - Show scalar, symmetric, and physical padding plus margin using canonical nested braces, commas, vertical keys, and `top/right/bottom/left` ordering.
    - Explain `spacing` versus `margin` versus `padding`, null/inherit versus zero/remove, override precedence, and reserved widget args.
    - Update the presentation skill and public docs from the same terminology; remove stale mirrored prose instead of keeping competing explanations.
    - Add demo slides that visibly distinguish spacing, margin, padding, and image framing.
    - Regenerate `.superdeck` contracts, exported JSON schema, generated Dart files, and affected goldens.
    - Update core, builder, and superdeck changelogs with the hard API break and new contract.
  - Acceptance:
    - All maintained authoring examples parse and round-trip.
    - No docs advertise block modifiers or `BoxStyler` for `SlideStyler.blockContainer`.
    - Generated artifacts match source and include normalized margin/padding.
  - Verification: `cd demo && fvm dart run superdeck_cli:main build`

- [ ] Task 8: Delete obsolete paths and run drift/completion gates
  - Dependencies: Task 7
  - Scope: S
  - Work:
    - Remove obsolete helpers, imports, generated types, tests, docs, and compatibility code revealed by analysis/unused-code checks.
    - Update PR #99's description to match the final code and remove resolved follow-up bullets.
    - Review the final diff for duplicate normalization, duplicated schemas, stale examples, generated-file drift, and unrelated changes.
  - Drift gates:
    - `rg -n -U 'blockContainer:\s*(\n\s*)?BoxStyler' packages demo docs .agents` returns no matches.
    - `rg -n -U 'blockContainer:[\s\S]{0,500}(WidgetModifier|\.wrap\()' packages demo docs .agents` returns no matches.
    - `rg -n '_alignmentValues|_slideBlockSchema|_slideSectionSchema' packages/playground/lib/features/ai/quick_agent/core/engine/schemas` returns no matches.
    - `rg -n '(padding|margin): \{ *(horizontal|vertical|top|right|bottom|left):' demo/slides.md docs .agents/skills/superdeck-presentations` returns no maintained one-line nested inset examples.
    - `git diff --check` is clean.

## Test strategy and final verification

Run generation before final tests so source and generated contracts are evaluated together:

```bash
fvm flutter pub run melos run build_runner:build --no-select
fvm flutter pub run melos run contracts:export --no-select
fvm flutter pub run melos run contracts:check --no-select
```

Run the full static and test gates:

```bash
fvm flutter pub run melos run analyze:dart --no-select
fvm flutter pub run melos run analyze:all --no-select
fvm flutter pub run melos run test --no-select
```

Run rendering and generated-demo verification:

```bash
cd packages/superdeck
fvm flutter test test/goldens/slide_goldens_test.dart

cd ../../demo
fvm dart run superdeck_cli:main build
fvm flutter test integration_test/layout_matrix_test.dart -d macos --fail-fast
```

Expected results:

- Generation produces no unexpected files after a second run.
- Exported contract schemas are current.
- Standard analysis has no errors, warnings, or infos.
- DCM unused-file/unused-code checks pass in a licensed environment; if licensing is unavailable, record that external blocker rather than claiming the cleanup gate passed.
- All unit/widget tests pass, including new contract, formatter, style, margin, image numeric, Playground parity, and overflow regressions.
- Goldens are intentionally reviewed and stable.
- Demo contracts rebuild cleanly and the layout matrix passes.

## Risks and stop conditions

- Risk: a custom `BlockStyler` can drift toward full `BoxStyler` over time. Mitigation: document the allow-list as an invariant and test only the supported surface; adding constraints, transforms, alignment, or modifiers requires a new design decision.
- Risk: authors may read margin as CSS sibling spacing. Mitigation: keep the frame semantics explicit in docs, examples, and exact-size tests; direct authors to section `spacing` for gutters.
- Risk: recursive directive formatting can damage arbitrary widget args. Mitigation: exact nested map/list/string round-trip tests and serializer idempotency are merge gates.
- Risk: deriving the AI schema may expose an adapter limitation. Mitigation: centralize any AI-compatible projection in core and stop rather than duplicating schemas again.
- Risk: Mix animation of padding/margin can produce transient geometry differences. Mitigation: add an intermediate-frame widget test; if the child content rectangle and animated box diverge, either make inset animation paint-only or omit block-container animation before merge.
- Stop if any implementation introduces a `BoxStyler` compatibility path, modifier escape hatch, duplicated layout schema, undocumented contract field, stale generated output, or skipped failing regression.

## Definition of done

- `BlockStyler` is the only public style accepted by `SlideStyler.blockContainer`, and it cannot express modifiers or competing geometry controls.
- Padding and margin share one validated authoring model, serialize to normalized physical edges, and render with exact documented precedence.
- Canonical nested examples use vertically formatted braces with required commas and round-trip through the real parser/serializer.
- Core, builder, superdeck, Playground, demo, docs, presentation skill, schemas, generated files, changelogs, and PR description agree.
- Every review follow-up listed on PR #99 is either fixed and tested or the implementation stops before merge.
- No compatibility shim, duplicate path, stale helper, unused code, or generated drift remains.
