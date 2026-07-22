# Plan: replace `superdeck_mermaid` (puppeteer) with `flutter_mermaid` runtime rendering

Status: proposed
Owner: maintainers
Target packages: `packages/superdeck`, `packages/plugins/mermaid`, `demo`, `docs`

## Summary

Replace the build-time Mermaid pipeline — `superdeck_mermaid`, which launches
headless Chrome via `puppeteer`, runs a vendored 2.5 MB `mermaid.min.js`
(v11.4.1), and screenshots each diagram to a PNG — with runtime rendering using
[`flutter_mermaid`](https://pub.dev/packages/flutter_mermaid), a pure
Dart/Flutter canvas renderer. Fenced ` ```mermaid ` blocks would render as live
Flutter widgets inside slides instead of being rewritten to image references
during the deck build.

This is an architectural change, not a dependency swap:

| | Today (`superdeck_mermaid`) | Proposed (`flutter_mermaid`) |
|---|---|---|
| When rendering happens | Deck build (CLI) | Slide build (runtime) |
| Renderer | Real mermaid.js in headless Chrome | Dart reimplementation of Mermaid |
| Output | PNG asset, fence rewritten to `![](...)` | Live widget, crisp at any scale |
| External requirements | Chrome/Chromium on build machine and CI | None |
| Diagram coverage | Everything mermaid.js 11 supports | 8 diagram types (see gap analysis) |
| Package maturity | mermaid.js (mature) behind our own plugin | v0.1.0, unverified publisher |

## Why do this

- **Removes the headless-browser toolchain.** No puppeteer, no Chrome
  requirement for `superdeck build`, no browser integration job in CI
  (`.github/workflows/test.yml` "Run Mermaid browser integration" step), no
  2.5 MB vendored JS blob in the repo.
- **Better output.** Vector-quality rendering at any slide scale instead of a
  fixed-DPI PNG screenshot; diagrams inherit live theming and can be
  interactive (`InteractiveMermaidDiagram` supports pan/zoom and node taps).
- **Simpler authoring loop.** Diagrams update on hot reload; no build step, no
  `.superdeck/mermaid/*.png` cache management, no stale-asset cleanup.
- **Fewer moving parts.** Deletes an entire plugin package plus its atomic
  file-write, sha256 cache-key, and browser-lifecycle machinery.

## Gap analysis and risks

### 1. Diagram-type regression (the big one)

`flutter_mermaid` 0.1.0 supports: flowchart (TD/TB/BT/LR/RL), sequence, pie,
gantt, timeline, kanban, radar, and XY charts.

The current pipeline runs real mermaid.js, and `docs/guides/mermaid-diagrams.mdx`
explicitly documents **class diagrams, state diagrams, entity-relationship
diagrams, and journey maps** — none of which `flutter_mermaid` renders. The
plugin's config surface also advertises mindmap, C4, gitGraph, quadrant,
sankey, architecture, block, packet, and treemap.

Mitigation options (decision needed, see Open decisions):

- a. Accept the regression; document the shrunken support matrix; render
  unsupported fences as a visible fallback (source code block + warning
  banner) so decks fail loud, not blank.
- b. Keep `superdeck_mermaid` published as an opt-in escape hatch for authors
  who need the full mermaid.js surface, while the runtime path becomes the
  default.

### 2. Rendering-fidelity risk

`flutter_mermaid` reimplements Mermaid's parser and layout in Dart. Even for
the eight supported types, expect divergence from mermaid.js: `%%{init: ...}%%`
directives, subgraphs, emoji in labels, `htmlLabels`, edge-label styling, and
theme variables may parse differently or not at all. A validation spike against
the exact sample diagrams in `docs/guides/mermaid-diagrams.mdx` is a
prerequisite, not a nice-to-have.

### 3. Supply-chain / maturity risk

v0.1.0, single release, unverified uploader, 4 likes, MIT, repo at
`github.com/JackCaow/flutter-mermaid`. Mitigations: pin an exact version
(`flutter_mermaid: 0.1.0`), and be prepared to fork/vendor under `btwld` if the
spike succeeds but upstream goes quiet. A fork also gives us a path to add the
missing diagram types ourselves.

### 4. Theming surface loss

Today's plugin accepts full Mermaid config (`themeVariables`, `themeCSS`,
`look: handDrawn`, per-diagram config, `%%{init}%%` overrides).
`flutter_mermaid` exposes a `MermaidStyle` with a handful of presets
(`.dark()`, `.forest()`, `.neutral()`). Decks relying on custom Mermaid
theming will change appearance. We map what we can from the deck's style
system and document the rest as unsupported.

## Proposed architecture

Render Mermaid fences at runtime inside the `superdeck` package's Markdown
pipeline. No build-time transform remains; ` ```mermaid ` fences flow through
the compiled deck untouched and are picked up by the renderer.

1. **Dependency** — add `flutter_mermaid: 0.1.0` (exact pin) to
   `packages/superdeck/pubspec.yaml`.
2. **Element builder** — add
   `packages/superdeck/lib/src/markdown/builders/mermaid_element_builder.dart`.
   In `SpecMarkdownBuilders` (`markdown_element_builders_registry.dart`), route
   code elements to it when the fence language is `mermaid`; all other
   languages keep going to `CodeElementBuilder`. The builder wraps
   `MermaidDiagram(code: ...)` in the block's constraints (via
   `BlockConfiguration.of(context)`) with a `FittedBox`/`ConstrainedBox` so
   diagrams scale to the slide like images do today.
3. **Styling** — resolve a `MermaidStyle` from the slide's resolved spec
   (dark default, matching today's `darkMode: true` + transparent background
   defaults). Add an optional style hook on `SlideSpec`/`DeckOptions` later if
   authors need per-deck overrides; not required for parity.
4. **Fallback for unsupported syntax** — wrap rendering so a parse/render
   failure (or an unsupported diagram keyword, detected up front from the
   first word of the fence) degrades to the existing syntax-highlighted code
   block plus a visible warning chip. The repo already ships a Mermaid TextMate
   grammar (`packages/superdeck/assets/grammars/mermaid.json`) used by
   `syntax_highlighter.dart` — keep it for exactly this path.
5. **Thumbnails/capture** — `flutter_mermaid` paints synchronously on canvas,
   so `SlideCaptureService`/thumbnail generation should capture diagrams with
   no asset preloading. Verify during the spike (an async-layout first frame
   would need a settle, same as images).
6. **Optional `@mermaid` widget block** — register a `mermaid` entry in
   `builtInWidgets` (`packages/superdeck/lib/src/builtins/`) so
   `@mermaid { code: ... }` works like `@image`/`@qrcode`. Low cost, but the
   fence path is the primary UX; treat this as a follow-up.

## Decommissioning `superdeck_mermaid`

- Delete (or deprecate, per Open decision 1) `packages/plugins/mermaid`:
  plugin, generator, vendored `mermaid.min.js`, and its four test suites.
- `demo/pubspec.yaml` — drop `superdeck_mermaid: ^1.0.0`.
- `demo/integration_test/plugin_visual_test.dart` — currently exercises
  `MermaidBuildPlugin` with a fake generator; replace with a runtime golden /
  widget test of the new builder rendering the same sample diagram.
- `.github/workflows/test.yml` — remove the "Run Mermaid browser integration"
  step and its `SUPERDECK_RUN_BROWSER_TESTS` gating.
- Docs:
  - `docs/guides/mermaid-diagrams.mdx` — rewrite: shrink the supported-types
    list to the eight `flutter_mermaid` types, delete the class/state/ER/journey
    sections and the "Build process"/`SuperDeckRunner` registration section,
    document runtime behavior, theming, and the unsupported-syntax fallback.
  - `docs/guides/plugins.mdx` and `docs/reference/plugin-api.mdx` — both use
    `MermaidBuildPlugin` as the canonical build-plugin example; swap in another
    example (e.g. the PDF plugin) so the plugin API docs stay valid.
  - `.agents/skills/superdeck-presentations/references/` — update
    `authoring.md` and `runtime-customization.md` references.
  - `docs.json` — keep the guide entry, contents change only.

## Phases

**Phase 0 — validation spike (gate for everything else).**
Build a scratch page in the demo/playground rendering every sample diagram
from `docs/guides/mermaid-diagrams.mdx` with `MermaidDiagram`, on macOS and
web. Produce a pass/fail matrix (diagram type × feature: subgraphs, emoji
labels, init directives, notes/loops/alt in sequence, etc.). Exit criteria:
flowchart + sequence render acceptably for presentation use. If the spike
fails, stop and reconsider (fork-and-fix upstream, or stay on the build
plugin).

**Phase 1 — runtime rendering in `superdeck`.**
Dependency pin, `MermaidElementBuilder`, registry routing, styling resolution,
unsupported-syntax fallback, widget tests (golden per supported diagram type),
thumbnail-capture verification. Demo slides gain a Mermaid slide (today
`demo/slides.md` has none — add one so the demo actually exercises the path).

**Phase 2 — remove the build plugin.**
Everything under "Decommissioning" above: package removal/deprecation, demo,
CI, melos wiring. Keep this a separate commit series from Phase 1 so the two
pipelines never coexist ambiguously in one change.

**Phase 3 — docs and release.**
Docs rewrites, CHANGELOG entries (`superdeck` minor with feature +
breaking-change note; `superdeck_mermaid` final deprecation release if kept),
migration note for existing decks: "delete `MermaidBuildPlugin()` from your
runner; fences now render natively; these diagram types are no longer
supported: …".

## Testing plan

- Unit: language routing in `SpecMarkdownBuilders` (mermaid → new builder,
  everything else → `CodeElementBuilder`); unsupported-keyword detection.
- Widget/golden: one golden per supported diagram type, light + dark.
- Fallback: invalid syntax and unsupported types render the code-block
  fallback, never throw into the slide tree.
- Integration: replace `plugin_visual_test.dart` scenario with runtime
  rendering; run existing capture/thumbnail tests over a Mermaid slide.
- CI: confirm the browser-integration job is gone and no job needs Chrome for
  Mermaid anymore.

## Open decisions

1. **Hard cutover vs. escape hatch.** Delete `packages/plugins/mermaid`
   outright, or keep it published-but-deprecated for authors needing
   class/state/ER/etc.? Recommendation: keep it for one deprecation cycle,
   remove from the default docs path immediately.
2. **Depend vs. fork.** Pin `flutter_mermaid 0.1.0` from pub, or fork under
   `btwld` for control over fixes and missing diagram types? Recommendation:
   pin for the spike; decide on forking based on how many spike issues need
   upstream patches.
3. **Unsupported-diagram UX.** Warning chip + source fallback (recommended)
   vs. build-time validation error in the CLI.
