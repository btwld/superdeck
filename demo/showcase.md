---

@section {
  flex: 2
}
@block {
  align: center
}
# SuperDeck {.heading}
# Presentations Reimagined {.subheading}

---

## What is SuperDeck? {.heading}

@block

SuperDeck is a presentation framework that transforms how developers create slides.

- Write slides in **Markdown** - familiar syntax, version-controlled
- Render with **Flutter** - cross-platform, beautiful UI
- Extend with **custom widgets** - interactive, live demos

---

@block {
  flex: 2
  align: centerLeft
}
### Traditional Tools {.heading}

@block {
  flex: 3
}

#### PowerPoint/Keynote

- Binary files, poor version control
- Limited code formatting
- No live components
- Platform-dependent

#### SuperDeck

- Plain text Markdown
- Git-friendly diffs
- Live Flutter widgets
- Runs everywhere Flutter runs

---

@section {
  flex: 2
}
@block {
  align: center
}
## "Write once, present anywhere. Version control everything." {.heading}

##### The SuperDeck Philosophy {.subheading}

---

@block {
  flex: 2
  align: centerLeft
}
### Hot Reload {.heading}

Edit your slides and see changes instantly - no rebuild needed.

@block {
  flex: 3
}

- **Live Preview** - Changes appear in milliseconds
- **State Preserved** - Stay on current slide while editing
- **Error Recovery** - Graceful handling of syntax errors
- **Watch Mode** - CLI monitors file changes automatically

---

### Markdown Syntax {.heading}

@block {
  flex: 2
}

```markdown
---

## Slide Title {.heading}

@block

Your content here with **bold**
and *italic* text.

- Bullet points
- Code blocks
- Custom widgets

---
```{.code}

---

@section

@block {
  flex: 1
}
## Layout System {.heading}

How SuperDeck organizes content on slides.

@section {
  flex: 3
  align: topLeft
}

@block {
  flex: 1
}
#### Sections

Horizontal rows that divide the slide vertically.

```markdown
@section {
  flex: 2
}
```

@block {
  flex: 1
}
#### Columns

Vertical divisions within sections.

```markdown
@block {
  flex: 3
  align: center
}
```

@block {
  flex: 1
}
#### Blocks

Content containers with markdown or widgets.

```markdown
@widget {
  name: "chart"
}
```

---

## Layout Types {.heading}

@block

| Layout | Structure | Best For |
|--------|-----------|----------|
| Title | Single centered section | Opening, section dividers |
| Standard | Title row + body row | Default content slides |
| Two-Column | Side-by-side blocks | Comparisons, pros/cons |
| Three-Column | Three equal blocks | Categories, options |
| Title-Left | Title block + content | Feature highlights |
| Quote | Centered large text | Key takeaways, transitions |
| Table | Markdown table | Structured data comparisons |

---

### The Block System {.heading}

@block

SuperDeck uses three core block types:

- **Content Blocks** (`@block`) - Render markdown text, lists, tables
- **Widget Blocks** (`@widget`) - Embed custom Flutter components
- **Built-in Widgets** (`@image`, `@dartpad`, `@qrcode`) - Pre-configured widgets

Each block supports:
- `flex` - Relative sizing (default: 1)
- `align` - Content positioning (e.g., `center`, `topLeft`)
- `scrollable` - Enable overflow scrolling

---

### Build Pipeline {.heading}

@block

The CLI processes your markdown through multiple stages:
1. **Parse** - Extract frontmatter and block directives
2. **Transform** - Convert to widget tree
3. **Render** - Flutter builds the UI

---

@block {
  flex: 2
  align: centerLeft
}
### Getting Started {.heading}

@block {
  flex: 3
}

#### Installation

```bash
# Add to your Flutter project
flutter pub add superdeck

# Create your slides
touch slides.md

# Build and watch
dart run superdeck_cli:main watch
```

#### Run

```bash
flutter run -d macos  # or chrome, windows, linux
```

---

## Styling System {.heading}

@section {
  flex: 3
}

@block {
  flex: 1
}

#### Global Themes

Define in `DeckOptions.styles`:

```dart
SuperDeckApp(
  options: DeckOptions(
    styles: {
      'default': borderedStyle(),
    },
  ),
)
```

@block {
  flex: 1
}

#### Per-Slide Styles

Apply via frontmatter:

```markdown
---
style: quote
---

> Your quote here
```

---

## Advanced Features {.heading}

@block

- **Code Highlighting** - Syntax-aware formatting
- **Custom Widgets** - Embed any Flutter widget
- **Thumbnails** - Auto-generated previews
- **Responsive** - Adapts to any screen size

---

@section {
  flex: 2
}
@block {
  align: center
}
## "The best presentation tool is the one that gets out of your way." {.heading}

##### Focus on content, not formatting {.subheading}

---

@section {
  flex: 2
  align: bottomCenter
}
# Start Building {.heading}
## github.com/leoafarias/superdeck {.subheading}

@section

@block {
  align: center
}
MIT License | Flutter & Dart
