# SuperDeck V2 Feature Validation Matrix

## Purpose
This document is the validation companion to `.planning/rewrite-v2-full-plan.md`.

The rewrite plan is only considered complete if every current v1 behavior has:
- a current implementation source
- a v2 owner
- a parity decision
- a validation gate
- a migration note when behavior or APIs change

This matrix exists to prevent architecture drift and accidental feature loss during the rewrite.

## Validation Rules

### Rule 1: Code wins over docs
Docs are useful, but rewrite decisions must be validated against current code and tests.

### Rule 2: Parsing behavior must be explicit
If a parser rule cannot be written as a testable rule, it is not stable enough for v2.

### Rule 3: Every current feature gets a decision
Each feature is one of:
- `preserve`
- `preserve with cleanup`
- `change intentionally`
- `remove intentionally`

Anything else is a planning gap.

### Rule 4: Every preserved feature needs a validation gate
Validation can be:
- contract test
- parser fixture test
- runtime/widget test
- CLI/integration test
- golden test
- migration test

### Rule 5: Operational flows are first-class
`setup`, `build`, `watch`, `publish`, `superdeck.yaml`, `styles.yaml`, and runtime bootstrap are part of the product surface, not implementation detail.

## Status Legend
- `covered` - explicitly accounted for in the rewrite plan
- `covered-open` - accounted for, but an explicit design decision still needs to be frozen
- `gap` - current feature exists but rewrite plan still needs more detail

## Authoring And Parsing Surface

| Feature | Current implementation refs | Current behavior | V2 owner | Decision | Plan status | Validation gate | Migration note |
|---|---|---|---|---|---|---|---|
| Slide boundaries | `packages/builder/lib/src/parsers/markdown_parser.dart`, `packages/builder/test/src/parsers/slide_parser_test.dart` | Top-level `---` splits slides, with fence-aware exceptions | `packages/authoring` | preserve with cleanup | covered | parser fixtures | none |
| Frontmatter extraction | `packages/builder/lib/src/parsers/front_matter_parser.dart`, `packages/core/lib/src/utils/yaml_utils.dart` | Per-slide YAML frontmatter with current permissive edge cases | `packages/authoring` | change intentionally | covered | parser fixtures | v2 makes invalid YAML and missing closing delimiters hard errors |
| Slide option passthrough | `packages/core/lib/src/models/slide_model.dart` | `title`, `style`, `template`, plus free-form args | `packages/contracts` | preserve | covered | contract round-trip | none |
| Stable slide keys | `packages/builder/lib/src/parsers/markdown_parser.dart` | Deterministic content-hash key with duplicate disambiguation | `packages/contracts`, `packages/authoring` | preserve | covered | parser fixtures, migration tests | preserve route/thumbnail stability where possible |
| Section directives | `packages/builder/lib/src/parsers/block_parser.dart`, `packages/builder/lib/src/parsers/section_parser.dart` | `@section` creates horizontal block groups | `packages/authoring` | preserve | covered | parser fixtures | none |
| Markdown block directives | `packages/builder/lib/src/parsers/block_parser.dart`, `packages/core/lib/src/models/block_model.dart` | `@column` and `@block` both mean markdown content block | `packages/authoring`, `packages/contracts` | change intentionally | covered | parser fixtures, migration tests | canonical v2 name is `@block` |
| Widget directives | `packages/builder/lib/src/parsers/block_parser.dart`, `packages/core/lib/src/models/block_model.dart` | `@widget { name: ... }` creates widget block | `packages/authoring`, `packages/contracts` | preserve | covered | parser fixtures | none |
| Widget shorthand aliases | `packages/builder/lib/src/parsers/block_parser.dart`, `packages/core/lib/src/models/block_model.dart`, docs | `@image`, `@dartpad`, `@qrcode`, and custom names map to widget blocks | `packages/authoring`, `packages/runtime_flutter` | preserve | covered | parser fixtures, runtime tests | none |
| Escaped directives | `packages/builder/lib/src/parsers/section_parser.dart` | `_@foo` is treated as literal `@foo` text | `packages/authoring` | preserve | covered | parser fixtures | none |
| Comment extraction | `packages/builder/lib/src/parsers/comment_parser.dart`, `packages/core/lib/src/models/slide_model.dart` | HTML comments become slide comments/notes | `packages/authoring`, `packages/contracts` | preserve with cleanup | covered | parser fixtures, migration tests | canonical semantic field is `notes`; migration covers serialized contract rename |
| Mixed markdown/directive aggregation | `packages/builder/lib/src/parsers/section_parser.dart` | Free markdown before/between/after directives is retained and merged into markdown blocks | `packages/authoring` | preserve | covered | parser fixtures | none |
| Balanced-brace directive options | `packages/core/lib/src/tag_tokenizer.dart` | Directive args are YAML-like maps with nested braces and source-located failures | `packages/authoring` | preserve | covered | parser fixtures | none |
| Fenced code recognition | `packages/builder/lib/src/parsers/fenced_code_parser.dart`, `packages/builder/lib/src/parsers/markdown_parser.dart`, `packages/core/lib/src/tag_tokenizer.dart`, `packages/core/lib/src/utils/code_fence.dart`, `packages/core/lib/src/markdown_syntaxes.dart` | Fence opener/closer handling is mostly shared, but fence-aware behavior is still interpreted in multiple layers | `packages/authoring` | preserve with cleanup | covered | parser fixtures | centralize fence-aware parsing without changing current backtick/tilde behavior |
| Mermaid fenced blocks | `packages/builder/lib/src/assets/asset_generation_pipeline.dart`, `packages/builder/lib/src/assets/mermaid_generator.dart` | ` ```mermaid` blocks become generated image assets | `packages/build_engine` | preserve | covered | integration tests | none |
| Dart fenced block formatting | `packages/builder/lib/src/tasks/dart_formatter_task.dart` | `dart` code fences are formatted during build | `packages/build_engine` | preserve | covered | integration tests | none |
| Hero markers on headers | `packages/core/lib/src/markdown_syntaxes.dart`, `packages/core/lib/src/hero_tag_helpers.dart` | Header `{.hero}` markers become runtime hero attributes | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Hero markers on images | `packages/core/lib/src/markdown_syntaxes.dart`, `packages/superdeck/lib/src/markdown/builders/image_element_builder.dart` | Image hero markers are supported | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Hero markers on fenced code | `packages/core/lib/src/markdown_syntaxes.dart`, `packages/superdeck/lib/src/markdown/builders/code_element_builder.dart` | Fenced code hero markers are supported | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Alert markdown blocks | `packages/superdeck/lib/src/markdown/builders/alert_element_builder.dart`, `packages/superdeck/test/markdown/markdown_builders_test.dart` | GitHub-style alerts render with custom styling | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Standalone markdown image promotion | `packages/superdeck/lib/src/markdown/image_block_syntax.dart`, `packages/superdeck/test/markdown/image_element_rendering_test.dart` | Standalone image lines are promoted to block images | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Inline markdown image limitation | `packages/superdeck/lib/src/markdown/image_block_syntax.dart` | Inline images inside paragraphs are intentionally not handled as rich widgets | `packages/runtime_flutter` | preserve intentionally | covered | regression test | document as non-goal |

## Build And Artifact Surface

| Feature | Current implementation refs | Current behavior | V2 owner | Decision | Plan status | Validation gate | Migration note |
|---|---|---|---|---|---|---|---|
| Canonical deck artifact | `packages/core/lib/src/deck_service.dart`, `docs/reference/contracts.mdx` | `.superdeck/superdeck.json` is the runtime contract | `packages/contracts`, `packages/build_engine` | preserve with versioning | covered | contract tests | rename to `.v2` form |
| Full deck debug artifact | `packages/core/lib/src/deck_service.dart`, `packages/core/lib/src/markdown_json.dart` | `.superdeck/superdeck_full.json` expands markdown blocks into AST JSON | `packages/contracts`, `packages/build_engine` | preserve | covered | integration tests | rename to `.v2` form |
| Generated assets manifest | `packages/core/lib/src/models/asset_model.dart`, `packages/core/lib/src/deck_service.dart` | Timestamp + file list manifest for generated assets | `packages/contracts`, `packages/build_engine` | preserve | covered | contract tests, integration tests | rename to `.v2` form |
| Build status artifact | `packages/core/lib/src/deck_service.dart` | Machine-readable `unknown/building/success/failure` state | `packages/contracts`, `packages/build_engine` | preserve | covered | integration tests | rename to `.v2` form |
| Error deck fallback | `packages/core/lib/src/deck_service.dart`, `packages/core/lib/src/models/slide_model.dart`, `packages/builder/lib/src/deck_builder.dart` | `DeckService` returns an error deck when the generated deck artifact cannot be loaded; markdown/build failures currently write `build_status.json` and usually leave the last good deck in place | `packages/build_engine`, `packages/runtime_flutter` | change intentionally | covered-open | integration tests | decide final failure policy: error slide, stale last-good deck, or typed runtime failure state |
| Deterministic generated asset names | `packages/core/lib/src/models/asset_model.dart` | Mermaid and thumbnail names are hash- or key-based | `packages/contracts`, `packages/build_engine` | preserve | covered | contract tests | none |
| Orphan generated asset cleanup | `packages/core/lib/src/deck_service.dart` | Unreferenced generated assets are pruned | `packages/build_engine` | preserve | covered | integration tests | none |
| Standard build pipeline | `packages/builder/lib/src/deck_builder.dart`, `packages/cli/lib/src/commands/build_command.dart`, `packages/superdeck/lib/src/utils/deck_watcher_io.dart` | Builder/task wiring currently duplicated | `packages/build_engine` | change intentionally | covered | integration tests | one factory in v2 |
| Build watch stream | `packages/builder/lib/src/deck_builder.dart` | Build stream emits started/completed/failed events | `packages/build_engine` | preserve with cleanup | covered | integration tests | none |
| Force rebuild behavior | `packages/cli/lib/src/commands/build_command.dart` | Asset dir and manifest can be cleared for full rebuild | `packages/build_engine`, `packages/cli` | preserve | covered | CLI integration tests | none |

## Runtime Surface

| Feature | Current implementation refs | Current behavior | V2 owner | Decision | Plan status | Validation gate | Migration note |
|---|---|---|---|---|---|---|---|
| File-backed deck loading | `packages/core/lib/src/deck_service.dart`, `packages/superdeck/lib/src/deck/deck_controller_builder.dart`, `packages/superdeck/lib/src/utils/constants.dart` | Debug IO runtimes where `kCanRunProcess` is true load from filesystem and can stream updates | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Bundled deck loading | `packages/superdeck/lib/src/deck/bundled_deck_service.dart`, `packages/superdeck/lib/src/deck/deck_controller_builder.dart`, `packages/superdeck/lib/src/utils/constants.dart` | Web/test/release-like runtimes load bundled JSON assets instead of file-backed streaming | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Route shape | `packages/superdeck/lib/src/deck/navigation_service.dart` | Router uses `/slides/:index` with root redirect | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Keyboard navigation | `packages/superdeck/lib/src/deck/navigation_events.dart`, `packages/superdeck/lib/src/deck/navigation_input_listener.dart` | Meta + arrows navigate slides | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Touch navigation | `packages/superdeck/lib/src/deck/navigation_events.dart`, `packages/superdeck/lib/src/deck/navigation_input_listener.dart` | Tap left/right and swipe navigate on touch devices | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Slide layout engine | `packages/superdeck/lib/src/rendering/slides/slide_view.dart`, `packages/superdeck/lib/src/rendering/blocks/block_widget.dart` | Sections stack vertically; blocks lay out horizontally with flex/alignment/scroll | `packages/runtime_flutter` | preserve | covered | golden/widget tests | none |
| Slide parts | `packages/superdeck/lib/src/rendering/slides/slide_parts.dart`, docs | Header/footer/background can be customized and read slide context | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Template system | `packages/superdeck/lib/src/deck/slide_template.dart`, `packages/superdeck/lib/src/deck/template_resolver.dart` | Templates bundle parts + style systems, with `template: none` opt-out | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Style merge from code + YAML | `packages/superdeck/lib/src/styling/schema/style_config.dart` | `StyleConfigLoader` can load `styles.yaml` and merge it with code-defined styles, with code winning conflicts; this is not automatic runtime startup behavior today | `packages/runtime_flutter` | preserve | covered-open | runtime tests | freeze strictness policy and whether loading stays opt-in |
| Built-in widget registry | `packages/superdeck/lib/src/widgets/widgets.dart`, `packages/superdeck/lib/src/deck/slide_configuration_builder.dart` | `image`, `dartpad`, `qrcode` are always available and can be overridden | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Custom widget parse/build contract | `packages/superdeck/lib/src/deck/widget_definition.dart`, `packages/superdeck/lib/src/rendering/blocks/block_widget.dart` | WidgetDefinition parses raw args and builds using block + slide context | `packages/runtime_flutter` | preserve with stronger typing | covered | runtime tests | move to typed outcomes |
| Notes/comments panel | `packages/superdeck/lib/src/ui/app_shell.dart`, `packages/superdeck/lib/src/ui/panels/comments_panel.dart` | Notes panel shows current slide comments when toggled | `packages/runtime_flutter` | preserve with rename cleanup | covered | runtime tests | `comments` becomes `notes` |
| Thumbnail panel | `packages/superdeck/lib/src/ui/app_shell.dart`, `packages/superdeck/lib/src/ui/panels/thumbnail_panel.dart` | Responsive thumbnail panel on side/bottom layouts | `packages/runtime_flutter` | preserve | covered | runtime/widget tests | none |
| Thumbnail generation | `packages/superdeck/lib/src/export/thumbnail_service.dart`, `packages/superdeck/lib/src/deck/deck_controller.dart` | Runtime thumbnails generated on demand with stale-state issues today | `packages/runtime_flutter` | preserve with cleanup | covered | runtime tests | none |
| Runtime asset cache | `packages/superdeck/lib/src/utils/asset_cache_store_io.dart`, `packages/superdeck/lib/src/utils/asset_cache_store_web.dart` | IO and web backends have different resolve/write semantics | `packages/runtime_flutter` | preserve with unification | covered | runtime tests | none |
| Plugin routes/actions/floating action | `packages/superdeck/lib/src/deck/superdeck_plugin.dart`, `packages/superdeck/lib/src/ui/app_shell.dart`, `packages/superdeck/lib/src/ui/panels/bottom_bar.dart` | Plugins contribute routes, inline actions, floating action, and async init | `packages/runtime_flutter` | preserve with stronger lifecycle typing | covered | runtime tests | none |
| Rebuild indicator | `packages/superdeck/lib/src/deck/deck_controller_builder.dart`, `packages/superdeck/lib/src/ui/app_shell.dart` | Runtime UI can show rebuild state driven by watcher | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Runtime bootstrap | `packages/superdeck/lib/src/utils/app_initialization.dart`, `packages/superdeck/lib/src/ui/superdeck_app.dart` | Syntax highlighting, desktop window init, and plugin init happen before app run | `packages/runtime_flutter` | preserve with cleanup | covered | runtime tests | none |
| PDF export | `packages/superdeck/lib/src/export/pdf_controller.dart`, `packages/superdeck/lib/src/export/pdf_export_screen.dart`, `packages/superdeck/lib/src/export/slide_capture_service.dart` | Runtime captures slides and writes PDF with progress and cancellation | `packages/runtime_flutter` | preserve | covered | runtime tests | none |
| Export mode rendering | `packages/superdeck/lib/src/deck/slide_configuration.dart`, `packages/superdeck/lib/src/markdown/markdown_hero_mixin.dart`, `packages/superdeck/lib/src/rendering/blocks/block_widget.dart` | Export mode suppresses interaction-only behavior such as hero flights and scroll behavior | `packages/runtime_flutter` | preserve | covered | runtime tests | none |

## CLI And Operational Surface

| Feature | Current implementation refs | Current behavior | V2 owner | Decision | Plan status | Validation gate | Migration note |
|---|---|---|---|---|---|---|---|
| `superdeck.yaml` load path | `packages/cli/lib/src/commands/base_command.dart`, `packages/superdeck/lib/src/utils/config_resolver_io.dart` | Current CLI is strict; runtime currently falls back more permissively | `packages/build_engine`, `packages/runtime_flutter`, `packages/cli` | change intentionally | covered-open | integration tests | freeze one shared policy |
| `setup` sample slides | `packages/cli/lib/src/commands/setup_command.dart` | Creates starter `slides.md` if missing | `packages/cli` | preserve | covered | CLI tests | none |
| `setup` pubspec patching | `packages/cli/lib/src/utils/update_pubspec.dart`, `packages/cli/lib/src/commands/setup_command.dart` | Adds `.superdeck/` and `.superdeck/assets/` to Flutter assets | `packages/cli` | preserve | covered | CLI tests | none |
| `setup` custom web index | `packages/cli/lib/src/utils/templates.dart`, `packages/cli/lib/src/commands/setup_command.dart` | Writes custom `web/index.html` with loading indicator | `packages/cli` | preserve | covered | CLI tests | none |
| `setup` macOS entitlements | `packages/cli/lib/src/commands/setup_command.dart` | Updates entitlements for network access and debug JIT/server settings | `packages/cli` | preserve | covered | CLI tests | none |
| `build` one-shot flow | `packages/cli/lib/src/commands/build_command.dart` | Runs setup checks, build pipeline, and writes artifacts | `packages/cli`, `packages/build_engine` | preserve with cleanup | covered | CLI integration tests | none |
| `watch` interactive flow | `packages/cli/lib/src/commands/build_command.dart` | Current watch mode is embedded in `build` with stdin commands and hard exit | `packages/cli`, `packages/build_engine` | change intentionally | covered | CLI integration tests | dedicated `watch` command |
| `publish` base-href | `packages/cli/lib/src/commands/publish_command.dart` | Base href derived from GitHub repo name for Pages | `packages/cli` | preserve | covered | CLI tests | none |
| `publish` index override | `packages/cli/lib/src/commands/publish_command.dart` | Temporarily replaces `web/index.html` during build and restores it later | `packages/cli` | preserve with cleanup | covered | CLI tests | move to scoped session |
| `publish` git worktree flow | `packages/cli/lib/src/commands/publish_command.dart` | Uses worktree for branch publishing without disrupting main worktree | `packages/cli` | preserve | covered | CLI integration tests | none |
| `publish` `.nojekyll` | `packages/cli/lib/src/commands/publish_command.dart` | Writes `.nojekyll` into published site | `packages/cli` | preserve | covered | CLI tests | none |
| `publish` dry-run | `packages/cli/lib/src/commands/publish_command.dart` | Simulates work without mutating filesystem or git state | `packages/cli` | preserve | covered | CLI tests | none |
| Runtime-triggered watch behavior | `packages/superdeck/lib/src/deck/deck_options.dart`, `packages/superdeck/lib/src/deck/deck_controller_builder.dart` | `watchForChanges` currently starts runtime watcher orchestration from `DeckOptions` | `packages/runtime_flutter`, `packages/cli`, `packages/migration_tools` | change intentionally | covered-open | migration tests | remove from core render options |

## Public API And Migration Surface

| Feature | Current implementation refs | Current behavior | V2 owner | Decision | Plan status | Validation gate | Migration note |
|---|---|---|---|---|---|---|---|
| Package entry surface | `packages/superdeck/lib/superdeck.dart`, `packages/core/lib/superdeck_core.dart` | Public API currently exposed through barrel exports | `packages/contracts`, `packages/runtime_flutter` | preserve with cleanup | covered-open | API audit | freeze public entry points |
| Deck JSON schema export | `packages/core/tool/export_contract_schemas.dart`, `packages/core/schema/superdeck.deck.schema.json` | Canonical schema export already exists | `packages/contracts` | preserve with versioning | covered | contract tests | add v2 schema versioning |
| `comments` field in artifacts | `packages/core/lib/src/models/slide_model.dart` | Contract currently serializes slide notes under `comments` | `packages/contracts`, `packages/migration_tools` | change intentionally | covered-open | migration tests | rename to `notes` |
| `@column` alias | `packages/core/lib/src/models/block_model.dart`, parser code, docs | Legacy alias still accepted widely | `packages/authoring`, `packages/migration_tools` | change intentionally | covered | parser + migration tests | canonicalize to `@block` |
| `template: none` | `packages/superdeck/lib/src/deck/template_resolver.dart`, tests | Reserved opt-out of default template behavior | `packages/runtime_flutter`, `packages/contracts` | preserve | covered | runtime tests | none |
| Built-in widget names | `packages/superdeck/lib/src/widgets/widgets.dart` | `image`, `dartpad`, `qrcode` are part of the public authoring contract | `packages/runtime_flutter`, `packages/migration_tools` | preserve | covered | runtime tests | none |

## Open Decisions To Freeze Before Implementation

1. Serialized `comments` -> `notes` migration
- Parser semantics now freeze canonical v2 `notes`.
- Artifact compatibility and migration messaging still need to be explicit.

2. Strictness of `superdeck.yaml`
- Current CLI and runtime behavior differ.
- v2 should freeze one policy and one failure shape.

3. `styles.yaml` placement
- Current plan keeps it runtime-side.
- Freeze whether that remains true for v2 or becomes build-time later.

4. `watchForChanges`
- Current plan removes it from core render options.
- Decide whether to ship a short-lived compatibility shim or hard migration.

## Next Validation Steps

1. Add a contract-and-migration matrix for renamed artifacts and public API changes.
2. Link each matrix row to concrete v2 tasks and tests before implementation starts.
3. Turn the remaining `covered-open` items into frozen decisions before implementation starts.
