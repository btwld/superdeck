---
title: Plain Markdown
---
# Plain Markdown

This slide keeps regular markdown content together.

- Heading
- Paragraph
- List

---
title: Section Columns
---
@section
@block
## Left Column

Author text in the first column.

@block
## Right Column

Author text in the second column.

---
title: Aligned Block
---
@block {align: center}
## Centered Callout

This block should keep its alignment option.

---
title: Image Widget
---
@image {
  src: assets/images/sample-diagram.png
  fit: cover
}

---
title: Weighted Layout
---
@section {
  flex: 2
}
@block {
  flex: 1
  align: topLeft
}
## Narrow Column

This block should keep its own flex and alignment.

@block {
  flex: 3
  scrollable: true
}
## Scrollable Wide Column

Line 1
Line 2
Line 3

@section {
  flex: 1
}
@block {
  align: bottomRight
}
## Footer Row

This lower section verifies vertical section flex.

---
title: Generic Widget
---
@widget {
  name: poll
  question: Ready to ship?
  choices:
    - yes
    - no
}

---
title: QR Code Widget
---
@qrcode {
  text: "https://superdeck.dev"
  size: 180
  errorCorrection: high
}

---
title: DartPad Widget
---
@dartpad {
  id: abc123
  theme: dark
  embed: true
  run: false
}

---
title: Escaped Directive
---
_@block {align: center}

This slide keeps a literal directive in markdown content.
