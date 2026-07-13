---
title: The system makes room
style: cover
layout: fullscreen
---

@section {
  spacing: 44
  align: center
}

@block {
  flex: 5
  align: centerLeft
  padding: { horizontal: 34, vertical: 28 }
}

#### NATIVE AUTHORING / VISUAL PROOF

# The system makes room.

## Eleven frames for layout, image control, and rich Markdown.

**Sections. Blocks. Images. Type.** One coherent visual language.

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: cover
  scale: 1.04
  flex: 6
  align: center
  padding: 0
  margin: { top: 14, right: 14, bottom: 14 }
}

---
title: The layout model
style: panels
---

@section { flex: 1 }

@block { align: centerLeft }

#### 01 / PREDICTABLE GEOMETRY

## The layout model explains itself.

@section {
  flex: 2
  spacing: 18
  align: center
}

@block { flex: 2 }

### SECTION = HEIGHT

Sections stack **vertically**. Their flex values decide how much of the slide each row receives.

@block { flex: 1 }

### 2×

This block gets twice the width of its neighbor.

@block { flex: 1 }

### 1×

The ratio stays stable as the canvas scales.

@section {
  flex: 2
  spacing: 18
  align: center
}

@block { flex: 1 }

#### MARGIN

Space outside the framed block.

@block { flex: 2 }

#### PADDING

Space inside the frame. **Decoration stays between them**, so the box model remains visible and teachable.

@block {
  flex: 1
  align: bottomRight
}

#### ALIGN

Content lands at any of nine anchor points.

---
title: Asymmetric composition
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 02 / SECTIONS + BLOCKS + IMAGES

## Editorial, asymmetric, still deterministic.

@section {
  flex: 5
  spacing: 28
  align: center
}

@block {
  flex: 4
  align: centerLeft
  padding: { right: 18 }
}

### Build hierarchy before decoration.

A strong composition begins with **one dominant relationship**. Here, a 4:7 split gives the image authority while the copy keeps a clear reading edge.

- **Flex** sets the proportion.
- **Spacing** creates the gutter.
- **Alignment** pins the content.

> The result feels art-directed because every constraint has a job.

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: cover
  scale: 1.12
  flex: 7
  align: centerRight
  padding: 0
  margin: { vertical: 6 }
}

@section {
  flex: 2
  spacing: 24
  align: center
}

@image {
  src: layout_showcase/assets/material_detail.png
  fit: cover
  flex: 2
  align: centerLeft
  padding: 0
}

@block {
  flex: 4
  align: centerLeft
  padding: { horizontal: 10 }
}

#### SECONDARY RHYTHM

Repeated image frames can change proportion without changing the rules around them.

@image {
  src: layout_showcase/assets/momentum_ribbon.png
  fit: cover
  scale: 1.18
  flex: 2
  align: centerRight
  padding: 0
}

---
title: Image fit behavior
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 03 / IMAGE FIT

## Same source. Two honest choices.

@section {
  flex: 1
  spacing: 24
  align: center
}

@block { flex: 1 }

#### CONTAIN / FULL FRAME

**Nothing is cropped.** Empty space is preserved.

@block { flex: 1 }

#### COVER / FULL BLEED

**The frame is filled.** Edges are intentionally cropped.

@section {
  flex: 5
  spacing: 24
  align: center
}

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: contain
  width: 560
  height: 420
  flex: 1
  align: center
  padding: 0
}

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: cover
  width: 560
  height: 420
  flex: 1
  align: center
  padding: 0
}

---
title: Image placement controls
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 04 / SCALE + ALIGNMENT

## Placement is a controlled variable.

@section {
  flex: 4
  spacing: 22
  align: center
}

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: contain
  scale: 0.72
  flex: 1
  align: topLeft
  padding: 0
}

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: cover
  scale: 1
  flex: 1
  align: center
  padding: 0
}

@image {
  src: layout_showcase/assets/architectural_steps.png
  fit: cover
  scale: 1.35
  flex: 1
  align: bottomRight
  padding: 0
}

@section {
  flex: 1
  spacing: 22
  align: topLeft
}

@block { flex: 1 }

#### 72% / TOP LEFT

Full image, deliberate quiet space.

@block { flex: 1 }

#### 100% / CENTER

The reliable default crop.

@block { flex: 1 }

#### 135% / BOTTOM RIGHT

An intentional detail view.

---
title: Markdown hierarchy
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 05 / RICH MARKDOWN

## The content model has range.

@section {
  flex: 4
  spacing: 42
  align: topLeft
}

@block { flex: 5 }

### Inline hierarchy

**Bold establishes consequence.** *Italic adds a second voice.* ~~Strikethrough retires the old idea.~~ A [link creates a path](https://superdeck.dev), and `inline code` names the mechanism.

> Typography can carry structure before a single custom widget enters the frame.

@block { flex: 4 }

### List rhythm

- **Lead** with the decision.
- *Qualify* it with context.
- Use `code` for exact syntax.

1. Establish the frame.
2. Repeat the cadence.
3. Break the pattern once.

@section {
  flex: 1
  spacing: 22
  align: center
}

@block { flex: 1 }

#### STRONG

**Make the signal unmistakable.**

@block { flex: 1 }

#### EMPHASIS

*Change the tone without changing size.*

@block { flex: 1 }

#### LINK + CODE

[Open the docs](https://superdeck.dev) or use `@section`.

---
title: Table-driven storytelling
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 06 / TABLES

## Dense information can still breathe.

@section {
  flex: 5
  spacing: 34
  align: center
}

@block {
  flex: 7
  align: centerLeft
}

| Layout signal | Before | After | Movement |
| :-- | --: | --: | --: |
| Time to first read | 8.4 s | **2.6 s** | **−69%** |
| Competing focal points | 7 | **2** | **−71%** |
| Grid exceptions | 12 | **1** | **−92%** |
| Review confidence | 54% | **91%** | **+37 pt** |

@block {
  flex: 3
  align: centerLeft
  padding: { left: 10 }
}

#### THE READING

## 3.2×

faster orientation after the hierarchy was simplified.

> A table earns attention when the comparison—not the border—is the story.

---
title: GitHub alerts
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 07 / GITHUB ALERTS

## Guidance with the right degree of urgency.

@section {
  flex: 2
  spacing: 18
  align: topLeft
}

@block { flex: 1 }

> [!NOTE]
> **Sections own height.** Blocks inside them divide the available width.

@block { flex: 1 }

> [!TIP]
> Reuse a stable spacing rhythm, then change only the value that carries meaning.

@section {
  flex: 2
  spacing: 24
  align: topLeft
}

@block { flex: 1 }

> [!IMPORTANT]
> Keep the focal relationship obvious at thumbnail size and at full screen.

@block { flex: 1 }

> [!WARNING]
> Paint-only image scale can crop beyond its original fit. Review the final frame.

@block { flex: 1 }

> [!CAUTION]
> Do not hide critical state in color alone. Pair the accent with a clear label.

---
title: Indicators and readiness
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 08 / INDICATORS

## Status should scan before it explains.

@section {
  flex: 4
  spacing: 42
  align: topLeft
}

@block { flex: 5 }

### Release readiness

- [x] Layout contract locked
- [x] Image crops reviewed
- [x] Contrast checked at 1280 × 720
- [ ] Speaker notes approved
- [ ] Final export published

> **3 / 5 complete.** The remaining work is visible without opening another tool.

@block { flex: 5 }

### Signal board

| Workstream | State | Owner |
| :-- | :-- | :-- |
| Layout | **● READY** | Design |
| Content | **● REVIEW** | Editorial |
| Capture | **● READY** | QA |
| Export | **○ QUEUED** | Release |

**READY** means verified. *REVIEW* means a decision remains. `QUEUED` means the path is known.

---
title: A bounded extension point
style: compact
---

@section { flex: 1 }

@block { align: centerLeft }

#### 09 / NATIVE FIRST, EXTENSIBLE WHEN NEEDED

## One escape hatch, clearly bounded.

@section {
  flex: 5
  spacing: 26
  align: center
}

@block {
  flex: 3
  align: centerLeft
  padding: { right: 8 }
}

#### BUILT-IN AUTHORING

### Most of this deck is only three primitives.

- `@section` for vertical rhythm
- `@block` for Markdown content
- `@image` for visual media

**No custom content widget is required** for the layouts, tables, alerts, checklists, or image studies.

@image {
  src: layout_showcase/assets/material_detail.png
  fit: cover
  scale: 1.08
  flex: 4
  align: center
  padding: 0
}

@showcaseMetric {
  value: "01"
  label: Registered widget
  detail: This single metric card is the deliberately custom extension point in the content deck.
  accent: "#59D6C8"
  flex: 3
}

---
title: The outcome
style: closing
layout: fullscreen
---

@section {
  spacing: 50
  align: center
}

@image {
  src: layout_showcase/assets/momentum_ribbon.png
  fit: cover
  scale: 1.24
  flex: 4
  align: centerLeft
  padding: 0
  margin: { top: 26, bottom: 26, left: 26 }
}

@block {
  flex: 5
  align: centerLeft
  padding: { right: 54 }
}

#### 10 / THE OUTCOME

# Built to be seen.

## Every frame can be authored, inspected, and captured.

**Native layouts. Rich Markdown. Controlled imagery.** One bounded widget extension and three original image assets.
