# ADR 0001: Runtime Mermaid rendering for SuperDeck

- **Status:** Accepted, 2026-09-21. Implemented on `feat/superdeck-mermaid-core`.
- **Date:** 2026-09-21
- **Deciders:** Leo (maintainer)
- **Supersedes:** `docs/maintainers/flutter_mermaid_replacement_plan.md`
  (branch `origin/claude/mermaid-replacement-plan-56v2aw`, 2026-07-22), whose
  Phase 0 spike was never run and whose gap analysis is now out of date.

## 1. Context

### What SuperDeck does today

A fenced ` ```mermaid ` block is routed by one line in
`CodeElementBuilder` (`code_element_builder.dart:103`) to `MermaidCodeBlock`
(`mermaid_code_block.dart`), which renders `flutter_mermaid` 0.1.0's
`MermaidDiagram` with a transparent background, a light/dark `MermaidStyle`,
and an `errorBuilder` that shows `ErrorWidgets.detailed('Unable to render
Mermaid diagram', error)`.

This replaced a build-time pipeline (`packages/plugins/mermaid`: puppeteer,
headless Chrome, vendored `mermaid.min.js` 11.4.1, PNG per diagram). That
package is gone; `packages/superdeck/CHANGELOG.md` 1.0.0 records the swap as a
breaking change, and the guide was rewritten to a shrunken support matrix.

### The four concerns this ADR keeps separate

| Concern | Owner | What this ADR changed |
| --- | --- | --- |
| **Runtime diagrams** — a fence painted inside a presented slide | `MermaidCodeBlock` | The renderer behind that one adapter |
| **Deck previews** — the Wizard rendering the deck it generated | The same widget through `DeckController` | `keepLastGoodSceneOnError: false`, so a preview never shows a stale drawing |
| **Derived presentation thumbnails** — regenerable raster of a slide | `ThumbnailService` + `SlideCaptureService`, memory-cached | Nothing. Thumbnails stay derived and stay in `MemoryAssetCacheStore` |
| **Deck-owned image assets** — artwork a saved deck references by bare key | `DeckLibrary` → `<name>.assets/` | Nothing. A Mermaid fence is *source*, not an asset, and must not become one |

The last row is the important boundary: a Mermaid diagram is authored text that
lives in the Markdown. Turning diagrams back into generated files would re-enter
the build-time model this project deliberately left, and would put derived
artefacts inside the asset directory reserved for artwork the user cannot
regenerate.

The playground's file-backed editor was removed in the same delivery, so the
"live editing" affordance this ADR weighed — the package keeping the last good
scene while an author types — is no longer a SuperDeck use case. It is turned
off everywhere.

### SuperDeck's real Mermaid corpus

Extracted from the repository, not invented (34 unique diagrams):

| Source | Count | Families |
| --- | --- | --- |
| `docs/guides/mermaid-diagrams.mdx` (current, user-facing contract) | 9 | flowchart ×2, sequence, pie, gantt, timeline, kanban, radar-beta, xychart-beta |
| `mermaid_code_block_test.dart` `_supportedDiagrams` | 8 | same eight families |
| `plugin_visual_test.dart`, `runtime-customization.md` | 2 | flowchart |
| `docs/guides/mermaid-diagrams.mdx@c2e4dfd2` (build-plugin era, **lost** in the swap) | 15 | + classDiagram, stateDiagram-v2, journey, erDiagram, `%%{init}%%` directive |

Two facts about the corpus matter:

- `demo/slides.md` contains **no** Mermaid diagram. The runtime path is exercised
  only by a synthesized slide in `plugin_visual_test.dart`. The 2026-07 plan
  asked for a demo slide; it was never added.
- The AI generation prompts never emit Mermaid (`grep -i mermaid|diagram` over
  `packages/playground/assets/ai_prompts/` returns nothing), so generated decks
  add no corpus pressure.

## 2. Decision drivers

1. **Content preservation** — a diagram the author wrote must render, or fail
   visibly. No silent partial rendering (first-principles Principle 4).
2. **Coverage of the documented corpus**, and ideally of the four families the
   project already documented before the swap.
3. **Preview behaviour** — render the generated deck without blocking the UI
   thread, and never present a drawing that does not match its source.
4. **Capture fidelity** — the same widget tree must be capturable for
   thumbnails and PDF export (both already go through `SlideCaptureReadiness`).
5. **No new toolchain** — no browser, no Node, no build step; `superdeck build`
   must stay a pure Dart command.
6. **Maintenance and bus factor** — who fixes a parse bug found mid-talk.
7. **Web payload and startup**, because the demo ships to `superdeck-dev.web.app`.
8. **Reversibility** — how cheaply SuperDeck can change its mind.

## 3. Options

### Option 1 — adopt `mermaid_core` + `mermaid_flutter` behind a SuperDeck adapter

`orestesgaolin/mermaid` (Dominik Roszkowski, verified publisher
`roszkowski.dev`, MIT). Pure Dart pipeline: source → per-diagram parser →
model → text measurement → backend-neutral `RenderScene` → SVG (`mermaid_core`)
or `CustomPainter` (`mermaid_flutter`).

**Verified independently** (see §4). 28 diagram families, 34/34 of SuperDeck's
corpus rendered, line/column parse errors, built-in last-good-scene behaviour
for live editing, `MaterialMermaidTheme.fromTheme()` bridging Flutter
`ColorScheme`/`TextTheme` into the diagram theme, PNG and SVG renderers
available for future export needs.

### Option 2 — keep, and contribute to or fork, `flutter_mermaid`

The incumbent. Verified: 8 families render; class, state, journey, ER, mindmap
and gitGraph all fail with an untyped `Exception: Unable to parse diagram` (no
line, no column, no reason); three of four malformed inputs render silently.
One release (2026-03-05), last repository push the same day, 6 stars, 2 open
issues, unverified uploader, and the published archive is 14.4 MB because a
45 MB `build/` directory was shipped with it — never corrected in 6.5 months.

Contributing upstream is plausible in principle, but the missing six families
are not small patches: they are six parsers and six layout engines.

### Option 3 — official Mermaid JS through a WebView/JS adapter, or pre-rendered SVG

The only path to true parity, because it *is* mermaid.js. SuperDeck already ran
a variant of this (puppeteer at build time) and removed it deliberately.

- **WebView at runtime:** adds `webview_flutter` (no macOS/Linux desktop parity
  for the presenter), breaks `RepaintBoundary` capture on several platforms
  (platform views do not reliably appear in `toImage`), and ends thumbnail/PDF
  capture as it works today. Fails drivers 4 and 5.
- **Pre-rendered SVG at build time:** re-introduces Node/Chrome into
  `superdeck build`, ends live editing of diagrams (driver 3), and produces
  derived files that would have to live somewhere — colliding with the
  deck-owned asset boundary in §1.

Retained as a **targeted fallback**, not a default: an opt-in export-time
renderer for authors who need a family the Dart port cannot do.

### Option 4 — build and own the parser and renderer

`mermaid_dart` 0.1.0 (flowchart/graph parser only, no layout, no renderer, one
release 2026-06-27, 11 downloads/30 days) is the only Dart seed available, and
it covers one family. Option 1 already is this work, done by someone else, with
~19,400 lines of tests. Rejected unless the project decides diagram rendering is
core intellectual property, which nothing in the repository suggests.

### Parser nuance, verified

`@mermaid-js/parser` 2.0.0 (installed and inspected) registers initializers for
**architecture, gitGraph, info, packet, pie, radar, treemap** only. Flowchart,
sequence, class, state, ER, journey, gantt, timeline, kanban, mindmap, xychart,
quadrant, C4, sankey and block still come from the legacy jison grammars inside
the `mermaid` package. There is no reusable upstream parser for the families
SuperDeck cares most about, in any language other than JavaScript. **Every Dart
option is a hand-port, so 28 types is type coverage, not compatibility.** The
upstream project says so itself in `parity/TRACKER.md`.

## 4. Evidence

Everything below was executed on this machine with the pinned SDK
(`.fvm/flutter_sdk`, Dart 3.12.2 / Flutter 3.44.6). Scratch projects lived in
`/tmp` and are removed.

### 4.1 Corpus compatibility (`mermaid_core` 0.3.0, `ApproximateTextMeasurer`)

**34 / 34 rendered**, including every family in the current guide *and* the four
lost families:

```
rendered  flowchart     docs-guide-1 … docs-guide-2      (5, 8 nodes)
rendered  sequence      docs-guide-3                     (8 nodes)
rendered  pie/gantt/timeline/kanban/radar/xychart        (8–36 nodes)
rendered  classDiagram  legacy-doc-6                     (11 nodes)   ← lost family
rendered  stateDiagram  legacy-doc-7                     (35 nodes)   ← lost family
rendered  journey       legacy-doc-9                     (18 nodes)   ← lost family
rendered  er            legacy-doc-11                    (9 nodes)    ← lost family
rendered  flowchart     legacy-doc-12 (%%{init:…}%%)     (3 nodes)    ← lost feature
```

Feature probes that also render: subgraphs, emoji labels, markdown strings
(`"\`**bold**\`"`), `click`/`href`, `classDef`/`class`, `linkStyle`, all seven
node shapes, ELK layout via init directive, frontmatter `config:`,
`look: handDrawn`, `autonumber`/`loop`/`alt`/`Note over`, tabs, CRLF, comments.

### 4.2 Failure behaviour against mermaid.js 12.0.0 (ground truth executed via jsdom)

| Input | mermaid.js 12 | mermaid_core 0.3.0 | flutter_mermaid 0.1.0 |
| --- | --- | --- | --- |
| `A[Start --> B[Finish]` (unbalanced) | **error**, line 2 | **renders 1 node** `Start --> B[Finish` | **renders** |
| `A ~~> B` (invalid edge op) | **error**, lexical line 2 | **renders 2 nodes, edge dropped** | **renders** |
| prose line inside a flowchart | **error**, line 3 | **error**, line 3 ✓ | **renders** |
| `A[Start] -->` (missing target) | **error**, line 4 | **error**, line 2 ✓ | — |
| unknown diagram keyword | error | `UnsupportedError` + supported list ✓ | `Exception: Unable to parse diagram` |
| empty / `gr` (mid-typing) | error | `UnsupportedError` ✓ | error |

**The "no silent partial rendering" requirement is not satisfied by any pure
Dart option today.** `mermaid_core` is strictly better than the incumbent
(2 silent cases vs 3, plus line/column diagnostics), and matches mermaid.js on
the other cases, but two narrow parser bugs remain. They are fixture-shaped and
worth reporting upstream; that repository closed 78 issues in three months.

### 4.3 Performance (pinned SDK, `flutter test`, debug/JIT — pessimistic)

| Measurement | flutter_mermaid 0.1.0 | mermaid_flutter 0.3.0 |
| --- | --- | --- |
| First frame, 8 shared diagrams (`pumpWidget`) | 17.0 ms avg (13–25) | 21.4 ms avg (13–34) |
| 20 rebuilds, unchanged source | 1 ms total | 4 ms total |
| One-character source edit | 34 ms | ~34 ms (same path) |
| Scene build only, all 34 corpus diagrams | n/a (no public API) | 5.35 ms avg, 22.7 ms worst |
| 20 diagrams in one list, first frame | not measured | 62 ms |

Both memoize on `(source, theme)`, so an unrelated rebuild costs nothing. The
candidate is ~25 % slower on a cold render; neither is a live-preview problem at
SuperDeck's diagram sizes. **Performance is not a reason to move.**

### 4.4 Maintenance, supply chain, packaging

| | flutter_mermaid 0.1.0 | mermaid_core/_flutter 0.3.0 |
| --- | --- | --- |
| Publisher | unverified uploader | verified `roszkowski.dev` |
| Releases | 1 (2026-03-05) | 6 in 10 days (0.1.0 → 0.3.0) |
| Last repo push | 2026-03-05 | 2026-09-08 |
| Stars / forks / open issues | 6 / — / 2 | 24 / 2 / **0** (78 closed) |
| Contributors | 1 | 1 (+1 drive-by: `parlough`) |
| Tests | 64 KB `test/` | ~19,400 lines across core/flutter/elk; **200 `.mmd` fixtures**, incl. `upstream_*` sets |
| Parity documentation | none | `parity/` — per-diagram notes, `COMPATIBILITY.md` with explicit non-goals, evidence links |
| Published archive | 14.4 MB (ships a 45 MB `build/`) | 536 KB + 1.0 MB (+ `elk` 202 KB) |
| Transitive deps | none | `elk`, `katex_dart`, `path_parsing`, `meta` (first two same author) |
| Licence | MIT | MIT, + vendored dart_dagre (Apache-2.0) and embedded KaTeX fonts (OFL-1.1) |
| Pub points | 140/160 | 150/160 |
| SDK | Dart ≥3.0, Flutter ≥3.0 | Dart ^3.12.0, Flutter ≥3.35.0 (SuperDeck pins 3.12.2/3.44.6 ✓) |

Bus factor is **1 in both cases**. The difference is that one of them is
actively maintained, tests against upstream fixtures, and documents where it
diverges.

### 4.5 Adapter requirements discovered

- `MermaidDiagram` paints at the scene's natural size
  (`CustomPaint(size: scene.size)`); a narrower parent **crops** rather than
  scales, with no overflow error. A `FittedBox` wrapper is required to keep the
  behaviour the current guide promises ("diagrams adapt to the width assigned to
  their Markdown block").
- `keepLastGoodSceneOnError` defaults to **true**: on a parse error the previous
  scene stays visible, dimmed, with a compact overlay. Correct for the editor;
  **wrong for capture** — a thumbnail or a PDF page would show a stale diagram.
  The adapter must set it `false` everywhere except the live editor preview.
- `semanticNodes` defaults to **false**; enabling it exposes one semantics node
  per identified diagram node. Relevant to SuperDeck's accessibility story, and
  free.
- The `Mermaid.render()` switch references all 28 layout engines, so Dart's tree
  shaker cannot drop unused families. Web payload delta is unmeasured and is a
  spike exit criterion.

## 5. Decision

**Adopt Option 1: `mermaid_core` + `mermaid_flutter` behind a thin SuperDeck
adapter, gated on the spike in §6.** Keep `MermaidCodeBlock` as the only
integration point so the renderer stays replaceable.

Reasons, in order of weight:

1. It restores four diagram families SuperDeck already documented and lost, plus
   `%%{init}%%` directives, without re-introducing a browser toolchain.
2. Its failure behaviour is materially better than the incumbent's and closer to
   mermaid.js: typed exceptions with line and column, an explicit supported-type
   list, and one fewer silent-partial case.
3. Its live-editing model (memoized scenes, last-good scene with an error
   overlay) is the behaviour SuperDeck's own first-principles review asked for.
4. The incumbent is unmaintained by every available signal, and its errors are a
   single untyped string that cannot be shown usefully to an author.

### Material downside accepted

**SuperDeck would depend on a three-month-old 0.x package stack maintained by
one person, whose scene IR and theme semantics changed between 0.2.0 and 0.3.0**
(`SceneGroupRole` introduced, `MermaidTheme` equality widened, cluster title
geometry changed, frontmatter comment handling changed). Pin exact versions,
keep the adapter thin, and expect to read the changelog on every bump. Two
silent-partial parse cases (§4.2) ship with it.

## 6. What was delivered

Implemented on `feat/superdeck-mermaid-core`, not as a spike:

1. **Dependency.** `flutter_mermaid: ^0.1.0` → `mermaid_core: 0.3.0` and
   `mermaid_flutter: 0.3.0`, both pinned exactly.
2. **Adapter.** `MermaidCodeBlock` stays the only place the renderer is named.
   It wraps `MermaidDiagram` in a `FittedBox` so a diagram scales down to the
   width its Markdown block was given, derives the diagram theme from the app's
   Material colour scheme over a transparent background, turns on
   `semanticNodes`, and turns off `keepLastGoodSceneOnError`.
3. **Capture.** A diagram that cannot render reports
   `SlideCaptureReadiness.fail`, so PDF export stops and names the slide
   instead of writing a page without it. A rendered diagram completes the wait
   after the frame that drew it.
4. **The two silent-partial cases** (§4.2) are rejected before rendering by
   `checkMermaidSource`, which runs upstream's own flowchart parser, vendored
   verbatim under `packages/superdeck/lib/src/markdown/mermaid/vendor/` with
   its MIT licence and source commit, tightened in exactly two marked places.
   Using their grammar rather than a SuperDeck pattern matcher is what keeps
   quoted labels, `~~~`, subgraphs, shapes, `classDef`, `linkStyle`, `click`,
   init directives and frontmatter working. Upstream was not contacted; the
   two fixtures are ready to file when that is authorised, and the vendored
   file is deleted the day upstream rejects both inputs.
5. **Corpus.** `mermaid_corpus_test.dart` renders every Mermaid fence in the
   guide, the demo deck and the skills reference, so a documented diagram
   cannot stop rendering unnoticed. The demo deck gained a Mermaid slide, so
   the path is exercised by the integration and browser runs too.
6. **Docs.** The guide lists the restored families, states that the port is a
   hand-written re-implementation, and says failures are reported with their
   line rather than drawn half-finished.

### What the delivery did not do

- **No Node or mermaid.js in the product.** mermaid.js 12.0.0 was used once,
  locally, to record the reference behaviour in §4.2. The export-time
  JavaScript fallback (option 3) is closed for this delivery.
- **Web payload, measured.** Demo release web build, same machine and SDK,
  before and after the swap:

  | | before | after | delta |
  | --- | --- | --- | --- |
  | `main.dart.js` | 3.36 MB | 5.10 MB | **+1.74 MB** |
  | `main.dart.js` gzipped | 1.01 MB | 1.63 MB | **+0.62 MB** |
  | whole `build/web` | 47.7 MB | 49.5 MB | +1.7 MB |

  The tree shaker cannot drop unused diagram families, because
  `Mermaid.render()` switches over all 28 — as predicted in §4.5. At
  **+0.62 MB compressed** this is inside the 1.5 MB exit criterion agreed
  below, so the decision stands; it is the price of the restored families and
  it is worth re-measuring on every `mermaid_core` bump.

## 7. Reconsideration triggers

- `mermaid_core` publishes no release for **6 months**, or its issue tracker
  stops being answered (the incumbent's failure mode).
- A 0.x bump breaks the adapter twice in a row, or changes rendered output
  without a changelog entry.
- SuperDeck needs a family the Dart port does not implement, or needs pixel
  parity with mermaid.js for a customer artefact.
- The silent-partial cases in §4.2 are declined upstream *and* a SuperDeck deck
  is observed losing content because of them.
- Web payload or first-frame cost regresses past the exit criteria after an
  upgrade.
- Mermaid upstream ships a Langium grammar for flowchart/sequence/class/state,
  which would make a maintained Dart port materially cheaper — revisit who
  should own the parser.

## 8. Questions this decision answered

1. **Is restoring class/state/journey/ER a product goal?** Yes. They were
   documented before the build plugin was removed, and they render again.
2. **Silent partial rendering:** neither accepted nor deferred — both cases are
   rejected locally by the vendored patch, with the upstream fixtures kept for
   a report when contacting upstream is authorised.
3. **`demo/slides.md` had no Mermaid slide.** It has one now, with a flowchart
   and a class diagram.
4. **Export-time SVG (option 3, narrow form):** closed for this delivery. It
   stays available as the fallback named in §3 if a parity requirement ever
   makes it necessary.

## 9. Still open

- The vendored parser is a fork of one file. Re-check it on every
  `mermaid_core` bump, and delete it when upstream rejects both inputs.
- Web payload is +0.62 MB compressed (§6). Inside the agreed threshold, but
  re-measure on every bump; if a future release pushes it past 1.5 MB, the
  options are deferred loading of the diagram code or dropping the dependency
  for web only.
