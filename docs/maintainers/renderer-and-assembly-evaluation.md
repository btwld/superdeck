# Deferred evaluations: shared assembly and the Markdown renderer

Maintainer notes, 2026-09-21. These are the two items the first-principles
report left open after the correctness work (report §4, "Recheck assumptions
where the product has changed").

## 1. Shared slide assembly — evaluated, consolidated

**Question.** The CLI build and the editor's preview codec each assembled
slides from `MarkdownParser`, `SlideOptions`, `SectionParser` and
`CommentParser`. Extract one function, or leave them apart?

**Evidence.** The two were not merely similar, they were the same four calls in
the same order:

| | `DeckBuilder._runBuild` | `DeckMarkdownCodec.decode` |
| --- | --- | --- |
| split | `MarkdownParser().parse(markdown)` | `const MarkdownParser().parse(markdown)` |
| options | `SlideOptions.parse(raw.frontmatter)` | identical |
| sections | `SectionParser().parse(raw.content)` | identical |
| comments | `CommentParser().parse(raw.content)` | identical |
| around it | applies build plugins | wraps failures in `DeckFormatException` |

Empirically, the front-matter work already ran every recognition fixture
through both paths and asserted the same slide count, keys and errors
(`deck_markdown_codec_test.dart`, "front matter recognition parity"), and
rebuilding `demo/slides.md` after that change produced a byte-identical
`superdeck.json`.

**Decision.** Parity is proven, so consolidate: `assembleSlides(String)` now
lives in `packages/builder/lib/src/parsers/slide_assembler.dart` and both
callers use it. The differences above stayed with their callers, which is
where they belong — plugins are a build concern, and the editor's exception
type is an editor concern.

**Deliberately not done.** No pipeline framework, no shared "deck service", no
move of filesystem work or build status. The report asked for one small pure
function; that is what exists.

## 2. The Markdown renderer — evaluated, kept

**Question.** `flutter_markdown_plus` renders slide content. Keep, or replace?

**Decision: keep.** Nothing in this delivery depends on changing it, and no
evidence was produced that a replacement is better for SuperDeck's mix of
content. The correctness contracts the report asked for are now protected
around it, which is the condition the report set before reopening this.

**What a replacement would have to prove**, if anyone reopens it — this is the
method, not a result, because the comparison has not been run:

1. Render the same corpus on both renderers: the demo deck, the three fixture
   decks under `packages/builder/test/fixtures/real_decks/`, and the docs
   examples. Cover lists, tables, code blocks with the repo's syntax
   highlighter, images resolved through `AssetCacheStore`, links, blockquotes,
   GitHub alerts, selection and semantics.
2. Prove capture parity: thumbnails, `SlideCaptureReadiness` participation and
   a PDF export of the same deck, not just an on-screen frame.
3. Measure first-frame and rebuild cost per slide on macOS and web release
   builds, on the same decks.
4. Show a concrete defect or missing capability the current renderer cannot
   address. A working prototype is not a reason on its own.

**Related, already decided elsewhere.** Diagram rendering is not part of this
question: `docs/maintainers/adr/0001-runtime-mermaid-rendering.md` covers it,
and it is settled.

## 3. Work retired rather than finished

The file-backed editor was removed, and with it the reasons for several items
the report and its remediation plan tracked. Recorded so they are not
rediscovered as gaps:

| Retired | Why it no longer applies |
| --- | --- |
| Auto-save completion invariant (F3) | Nothing auto-saves. A deck is written when the reader saves it, from the document in memory. |
| Save-a-copy of an externally opened file | No file is opened from outside the SuperDeck folder. |
| Crash-safe writes for external files | Same: the only writer is the deck library, which writes new files through a temporary sibling and a rename. |
| External-edit conflict policy | Nothing watches a file, so nothing can conflict with an external edit. |
| Per-deck asset eviction on rebind | A save writes a new deck; it never replaces one, so there is nothing to evict. |

The autosave work still has value as evidence of the defect and the fix; it is
preserved on `fix/playground-save-safety` and `feat/playground-deck-assets`,
which are not part of the review stack.
