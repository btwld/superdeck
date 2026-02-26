# SuperDeck Layout Patterns

Reference of working layout patterns for AI-generated presentations.

---

## 1. Title Slide

Single centered section with H1 title and H2 subtitle.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 2,
      "blocks": [
        {
          "type": "block",
          "align": "center",
          "content": "# Main Title\n## Subtitle"
        }
      ]
    }
  ]
}
```

---

## 2. Standard Content (Title + Body)

Two sections: title row (flex:1) + body row (flex:3).

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 1,
      "blocks": [
        {"type": "block", "content": "## Slide Title"}
      ]
    },
    {
      "type": "section",
      "flex": 3,
      "blocks": [
        {
          "type": "block",
          "content": "Introduction text.\n\n- **Point 1:** Description\n- **Point 2:** Description\n- **Point 3:** Description"
        }
      ]
    }
  ]
}
```

---

## 3. Two-Column Layout

Title section + body section with 2 blocks side by side. Use `####` (H4) for column headers - smaller than slide title.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 1,
      "blocks": [
        {"type": "block", "content": "## Slide Title"}
      ]
    },
    {
      "type": "section",
      "flex": 3,
      "blocks": [
        {
          "type": "block",
          "flex": 1,
          "content": "#### Left Column\n\n- Item 1\n- Item 2\n- Item 3"
        },
        {
          "type": "block",
          "flex": 1,
          "content": "#### Right Column\n\n- Item A\n- Item B\n- Item C"
        }
      ]
    }
  ]
}
```

**Use for:** Comparisons, pros/cons, categories, before/after.

---

## 4. Three-Column Layout

Title section + body section with 3 blocks. Use `####` (H4) for column headers and add `align: "topLeft"` to section for consistent vertical alignment.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 1,
      "blocks": [
        {"type": "block", "content": "## Slide Title"}
      ]
    },
    {
      "type": "section",
      "flex": 3,
      "align": "topLeft",
      "blocks": [
        {
          "type": "block",
          "flex": 1,
          "content": "#### Column 1\n\nDescription text."
        },
        {
          "type": "block",
          "flex": 1,
          "content": "#### Column 2\n\nDescription text."
        },
        {
          "type": "block",
          "flex": 1,
          "content": "#### Column 3\n\nDescription text."
        }
      ]
    }
  ]
}
```

**Use for:** 3 items of equal importance (e.g., 3 species, 3 options, 3 pillars).

**Notes:**
- Without `align: "topLeft"`, columns may have inconsistent vertical positioning
- Use `####` (H4) not `###` (H3) for column headers - H3 is too large for narrow columns

---

## 5. Quote / Statement Slide

Single centered section with blockquote.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 2,
      "blocks": [
        {
          "type": "block",
          "align": "center",
          "content": "> \"The quote text goes here.\""
        }
      ]
    }
  ]
}
```

**Use for:** Impactful statements, transitions, breathing room between dense slides.

---

## 6. Side-by-Side (Title + Content)

Single section with 2 blocks: title/subtitle on left, content on right. Use `###` (H3) for title - smaller than standard slide titles since it shares space with content.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 2,
      "blocks": [
        {
          "type": "block",
          "flex": 2,
          "align": "centerLeft",
          "content": "### Section Title\n\nSubtitle or context"
        },
        {
          "type": "block",
          "flex": 3,
          "content": "- **Item 1:** Description\n- **Item 2:** Description\n- **Item 3:** Description"
        }
      ]
    }
  ]
}
```

**Use for:** Visual variety, when title needs more prominence alongside content.

**Caution:** Long titles may wrap awkwardly in narrow left column. Use `###` (H3) not `##` (H2) for title to fit the narrower space.

---

## 7. Closing Slide

Similar to title slide - centered H1 + H2.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 2,
      "blocks": [
        {
          "type": "block",
          "align": "center",
          "content": "# Thank You\n## Questions?"
        }
      ]
    }
  ]
}
```

---

## 8. Image Slide (REQUIRED layout for all images)

**ALWAYS use a single section with the image in its own block** (like the Title-Left pattern). This gives the image the full slide height. Never use a title section on top of image slides. Never embed images inline within text content.

```json
{
  "sections": [
    {
      "type": "section",
      "flex": 2,
      "blocks": [
        {
          "type": "block",
          "flex": 3,
          "content": "### Slide Title\n\nIntroduction text.\n\n- **Point 1:** Description\n- **Point 2:** Description\n- **Point 3:** Description"
        },
        {
          "type": "block",
          "flex": 2,
          "content": "![A description of the illustration](path/to/image.png)"
        }
      ]
    }
  ]
}
```

**Use for:** Any slide that has an available image — content, title, or closing.

**Notes:**
- Single section with `flex: 2` (same as Title-Left pattern)
- Text block gets `flex: 3`, image block gets `flex: 2` (60/40 split)
- Use `###` (H3) for the title (not `##`) since it shares space with the image column
- Image fills its own column at the full height of the slide
- For title/closing slides, add `align: "center"` to the text block
- Only include the image if it is listed in the Available Images section

---

## Image Placement Guidelines

- **Maximum 3 images per presentation** — select the 3 most impactful slides
- **ALWAYS use Pattern 8** (single section, image in own block) — no title section on top
- **ALWAYS use a separate block for images** — never put `![](...)` inline within text content
- **Only use images from the Available Images section** — never invent image paths
- Each available image is mapped to a slide key (e.g., `intro: .superdeck/assets/slide-intro-illustration.png`)
- Place images on the slide matching their key

---

## Alignment Reference

| Value | Use Case |
|-------|----------|
| `center` | Title slides, quotes, closing slides |
| `centerLeft` | Side-by-side title blocks |
| `topLeft` | Multi-column sections (keeps headers aligned) |

---

## Flex Ratios

| Pattern | Title Section | Body Section |
|---------|---------------|--------------|
| Standard content | `flex: 1` | `flex: 3` |
| Quote/Title slides | `flex: 2` | - |
| Side-by-side blocks | - | `flex: 2` (title), `flex: 3` (content) |
| Image slide | `flex: 2` | `flex: 3` (text), `flex: 2` (image) |

---

## Known Issues

1. **Word breaks in narrow columns** - Long words in side-by-side layouts may break awkwardly
2. **Vertical misalignment** - Multi-column layouts need `align: "topLeft"` on section
3. **4+ blocks** - Avoid more than 3 blocks per section (gets cramped)
