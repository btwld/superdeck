![Superdeck logo](./assets/logo-dark.png#gh-dark-mode-only)
![Superdeck logo](./assets/logo-light.png#gh-light-mode-only)

# SuperDeck

Create visually appealing, interactive presentations in Flutter using Markdown.

![Screenshot](https://github.com/leoafarias/superdeck/assets/435833/42ec88e9-d3d9-4c52-bbf9-5a2809cca257)

### [View demo here](https://superdeck-dev.web.app)

### [Example code](https://github.com/leoafarias/superdeck/blob/main/demo/slides.md)

## Getting Started

1. **Install the CLI**:
   ```bash
   dart pub global activate superdeck_cli
   ```

2. **Set up your project**:
   ```bash
   superdeck setup
   ```

   This configures `pubspec.yaml`, macOS entitlements, creates `slides.md`, and sets up web assets.

3. **Add SuperDeck**:
   ```bash
   flutter pub add superdeck
   ```

4. Import the package and initialize SuperDeck:

   ```dart
   import 'package:flutter/widgets.dart';
   import 'package:superdeck/superdeck.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SuperDeckApp.initialize();

     runApp(
       SuperDeckApp(
         options: DeckOptions(
           debug: false,
           widgets: const {
             'twitter': TwitterWidgetDefinition(),
           },
         ),
       ),
     );
   }

   class TwitterWidgetDefinition extends WidgetDefinition<Map<String, Object?>> {
     const TwitterWidgetDefinition();

     @override
     Map<String, Object?> parse(Map<String, Object?> args) => args;

     @override
     Widget build(BuildContext context, Map<String, Object?> args) {
       final username = args['username'] as String? ?? '';
       final tweetId = args['tweetId'] as String? ?? '';
       return Text('Twitter: @$username ($tweetId)');
     }
   }
   ```

## Block-Based System

SuperDeck uses blocks for flexible content layouts.

### Block Types

- `@column` - Renders markdown (text, lists, code, tables)
- `@section` - Horizontal container for multiple blocks
- `@widget` - Embeds custom Flutter widgets

Built-in widgets (`image`, `dartpad`, `qrcode`, `mermaid`) use shorthand syntax like `@image { ... }`.

### Basic Layout Example

```markdown
---

@column

# Welcome to SuperDeck

Your awesome slides start here!

@column

- Create beautiful slides using markdown
- Arrange content using the block-based system
- Customize with images, widgets, and more

---
```

### Multiple Columns Example

```markdown
---

@column {
  align: center_left
  flex: 2
}

## Left Column Content

- Item 1
- Item 2
- Item 3

@column {
  align: center_right
}

## Right Column Content

With some explanatory text.

---
```

### Alignment

Available options: `topLeft`, `topCenter`, `topRight`, `centerLeft`, `center`, `centerRight`, `bottomLeft`, `bottomCenter`, `bottomRight`

### Flex

Control relative sizing with `flex`:

```markdown
@section
@column {
  flex: 2
}
Takes twice the space
@column
Normal size
```

### Image Block Example

```markdown
@column

## Image Example

@column

![example_image](https://picsum.photos/800/600) {.cover}
```

### DartPad Block Example

```markdown
@dartpad {
  id: your_dartpad_id
  theme: dark
  run: true
}
```

### Widget Block Example

```markdown
@widget {
  name: colorPalette
  schema: true
  prompts: [tropical, vibrant, pastel]
}
```

## Slide Examples

### Simple Slide with a Single Column

```markdown
---

@column

# My Slide Title

- Point 1
- Point 2
- Point 3

---
```

### Multi-Column Layout

```markdown
---

@column {
  align: center_left
  flex: 2
}

# Left Content

- More content on the left side
- With a larger flex value

@column {
  align: center_right
}

# Right Content

This content takes up less space due to the default flex value of 1.

---
```

### Slide with Custom Widget

```markdown
---

@column

# Tweet Example

@twitter {
  username: username
  tweetId: 1234567890
}

@column

# More content

---
```

### Slide with Mermaid Diagram

```markdown
---

@column

# Diagram Example

```mermaid
graph TD
    A[Start] --> B[Input]
    B --> C[Process]
    C --> D[Output]
    D --> E[End]
``` {.code}

---
```

### Slide with DartPad

```markdown
---

@column

# DartPad Example

@dartpad {
  id: example-dartpad-id
  theme: dark
}

@column

# Explanation

This code demonstrates how to use Flutter widgets.

---
```

### Slide with Image

```markdown
---

@column

# Image Example

![Example Image](https://example.com/image.png) {.cover}

@column

# Text alongside the image

---
```

### Advanced Layout with Nested Sections

```markdown
---

@section

@column {
  align: center
}

# Main Header

@section {
  flex: 2
}

@column {
  align: center_left
}

## Left Content

@column {
  align: center_right
}

## Right Content

---
```

## Configuration

### DeckOptions

Configure your app with `DeckOptions`:

```dart
SuperDeckApp(
  options: DeckOptions(
    baseStyle: SlideStyle(),
    styles: {
      'announcement': SlideStyle(),
      'quote': SlideStyle(),
    },
    widgets: const {
      'twitter': TwitterWidgetDefinition(),
    },
    parts: const SlideParts(),
    debug: false,
  ),
);
```

### Custom Widgets

Register and use custom widgets:

```dart
widgets: const {
  'twitter': TwitterWidgetDefinition(),
},
```

```markdown
@twitter {
  username: username
  tweetId: 1234567890
}
```

### Assets

SuperDeck generates and manages:
- Images (PNG, JPEG, GIF, WEBP, SVG)
- Thumbnails
- Mermaid diagrams

## Styling

Configure with `DeckOptions`:

```dart
baseStyle: SlideStyle(),
styles: {
  'announcement': SlideStyle(),
  'quote': SlideStyle(),
},
```

Add CSS classes:

```markdown
## Styled Heading {.highlight}

![example_image](https://picsum.photos/800/600) {.cover}
```

## Slide Parts

Add consistent UI to all slides:

```dart
parts: SlideParts(
  header: CustomHeaderPart(),
  footer: CustomFooterPart(),
  background: CustomBackgroundPart(),
),
```

## API Reference

### Block Model

- `SectionBlock` - Horizontal containers
- `ContentBlock` - Renders markdown
- `WidgetBlock` - Hosts Flutter widgets

### Asset Model

Generated resources:
- Image variants (PNG, JPEG, GIF, WEBP, SVG)
- Slide thumbnails
- Mermaid diagrams

### Slide Model

- `key` - Unique identifier
- `options` - Configuration and metadata
- `sections` - Section blocks
- `comments` - Presenter notes

## Advanced Features

### Code Highlighting

```markdown
```dart
void main() {
  print('Hello, world!');
}
``` {.code}
```

### Animations

```markdown
# This title will animate {.animate}
```

### Alerts

```markdown
> [!NOTE]
> This is a note.

> [!WARNING]
> This is a warning.

> [!CAUTION]
> This is a caution.
```

## Configuration

Create `superdeck.yaml` to set default options for all slides.

## Development

### Run CLI Locally

```bash
cd demo
dart ../packages/cli/bin/main.dart <command> [arguments]

# Build slides
dart ../packages/cli/bin/main.dart build

# Watch mode
dart ../packages/cli/bin/main.dart build --watch
```

### Demo App

**Run the demo**:
1. Navigate: `cd demo`
2. Build: `dart ../packages/cli/bin/main.dart build`
3. Run: `flutter run`

**Development workflow**:

Terminal 1:
```bash
cd demo
dart ../packages/cli/bin/main.dart build --watch
```

Terminal 2:
```bash
cd demo
flutter run
```

Edit `demo/slides.md` and hot reload (`r`) to see changes.

**CLI Commands**:
- `build` - Build once
- `build --watch` - Watch mode
- `setup` - Configure SuperDeck
- `--help` - Show commands

**Demo Structure**:
- `demo/slides.md` - Presentation content
- `demo/superdeck.yaml` - Configuration
- `demo/lib/main.dart` - App entry point
- `demo/assets/` - Static assets

See `demo/slides.md` for examples and API documentation for advanced usage.
