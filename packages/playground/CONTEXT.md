# Playground Editor

The live Markdown editor in the SuperDeck playground app: a three-panel screen
where edits to Markdown re-render slide previews in real time.

## Language

**Deck**:
The ordered set of slides parsed from the editor's Markdown buffer.
_Avoid_: presentation, document

**Slide**:
One unit of deck content, delimited in Markdown by `---` separators.
_Avoid_: page, card

**Active Slide**:
The slide the editor caret currently sits in; its index is owned solely by `EditorState.activeSlideIndex`.
_Avoid_: current slide, selected slide

**Thumbnail**:
A cached PNG render of a slide, shown in the Preview Sidebar for every slide except the Active Slide.
_Avoid_: preview image, snapshot

**Preview Sidebar**:
The left panel that lists every slide — the Active Slide rendered live, the rest as Thumbnails.
_Avoid_: slide list, filmstrip

**Thumbnail Refresher**:
The module that regenerates Thumbnails when the deck first loads and whenever the Active Slide changes.
_Avoid_: thumbnail service (that is superdeck's capture pipeline), debouncer

## Relationships

- A **Deck** contains one or more **Slides**
- Exactly one **Slide** is the **Active Slide** at any time
- Every **Slide** except the **Active Slide** appears in the **Preview Sidebar** as a **Thumbnail**
- The **Thumbnail Refresher** regenerates **Thumbnails** when the deck first loads and when the **Active Slide** changes

## Example dialogue

> **Dev:** "When the caret moves from slide 2 to slide 3, what regenerates?"
> **Domain expert:** "Slide 3 becomes the Active Slide and renders live. Slide 2 is no longer active, so the Thumbnail Refresher captures a fresh Thumbnail for it — its content has settled."
> **Dev:** "And while I'm typing inside slide 3?"
> **Domain expert:** "Nothing regenerates. Slide 3 is the Active Slide; the Preview Sidebar already shows it live, so its Thumbnail can wait until you leave it."

## Flagged ambiguities

- "current slide" was used for both the **Active Slide** (editor caret) and `DeckController.presentation.currentIndex` (presentation-mode routing) — resolved: these are distinct concepts; **Active Slide** refers only to the editor.
