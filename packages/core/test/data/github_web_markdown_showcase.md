# GitHub Web Markdown Showcase

This document exercises the Markdown features enabled by
`md.ExtensionSet.gitHubWeb`, including tables, task lists, alerts, footnotes,
and automatic heading IDs. It is intended for visual inspection and
regression testing.

## Headings

# Level 1 Heading

## Level 2 Heading

### Level 3 Heading

#### Level 4 Heading

##### Level 5 Heading

###### Level 6 Heading

Heading with **strong** and *emphasis* inside
================================================

Setext level-two heading
------------------------------------------------

### Paragraphs & Inline Styling

Paragraph with **bold**, *italic*, ~~strikethrough~~, `inline code`, emoji
:sparkles:, a color swatch `#FF7F50`, and an autolink <https://superdeck.dev>.
We also escape reserved
characters like \*\_\` to keep them literal.

Paragraph with a [reference link][superdeck-site] and inline HTML for
<u>underline</u> support.

### Lists

- Bullet item one
- Bullet item two
  - Nested bullet
  - Nested bullet with `code`
- Bullet item three

1. Ordered item one
2. Ordered item two with **bold**
3. Ordered item three

Start numbering at 3:

3. Custom start ordered list
4. Continues counting

- [ ] Unchecked task
- [x] Completed task with :tada:
- [ ] Task with nested steps
  - [x] Step one
  - [ ] Step two

### Blockquotes & Alerts

> Blockquote introducing a nested quote.
>
> > Nested blockquote with **strong** emphasis.

> [!NOTE]
> This is a note alert block.

> [!TIP]
> Tips can include lists:
> - Keep content concise.
> - Highlight key actions.

> [!IMPORTANT]
> Important alerts may include **bold**, *italic*, and links like
> [documentation](https://docs.github.com).

> [!WARNING]
> Warning alerts help highlight risky operations.

> [!CAUTION]
> Caution alerts can mix **bold** text with nested lists:
> 1. First cautionary step
> 2. Second cautionary step with `code`

### Horizontal Rule

---

### Inline & Block Code

Use `InlineCodeWidget` for small snippets.

```dart
// Dart code sample
void main() {
  print('Hello, Markdown!');
}
```

```json
{
  "name": "superdeck",
  "features": ["markdown", "slides", "widgets"]
}
```

### Tables

| Feature        | Enabled | Notes                         |
| :------------- | :-----: | ----------------------------: |
| Tables         |   ✅    | Left-aligned header           |
| Task Lists     |   ✅    | Checkbox support              |
| Footnotes      |   ✅    | Appears in references section |

### Links & Images

Inline link to [SuperDeck](https://superdeck.dev "SuperDeck Homepage").

Autolink for issue tracking <https://github.com/superdeck>.

![Sample slide thumbnail](https://placehold.co/400x200 "Slide preview")

Reference-style link to [SuperDeck Docs][superdeck-site].

### Footnotes

Statement referencing a footnote.[^intro]

Multiple references can point to the same footnote.[^shared]

Another reference to the shared note.[^shared]

### Complex Nesting

- Parent item with blockquote
  > Nested quote inside list item.
- Parent item with table

  | Column A | Column B |
  | -------- | -------- |
  | Value 1  | Value 2  |

- Parent item with code block

  ```bash
  melos run analyze
  ```

### Footnote Definitions & References

[^intro]: This footnote explains the introductory reference.
[^shared]: Shared footnote definition supporting multiple references.

[superdeck-site]: https://docs.superdeck.dev "SuperDeck Documentation"
