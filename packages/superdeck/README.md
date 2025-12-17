![Superdeck logo](./assets/logo.png)

SuperDeck enables you to craft visually appealing and interactive presentations directly within your Flutter apps, using the simplicity and power of Markdown.

![Screenshot](https://github.com/leoafarias/superdeck/assets/435833/42ec88e9-d3d9-4c52-bbf9-5a2809cca257)

### [View demo here](https://superdeck-dev.web.app)

### [Example code](https://github.com/leoafarias/superdeck/blob/main/demo/slides.md)

## Getting Started

Follow these steps to integrate SuperDeck into your Flutter project:

1. Install the `superdeck` package by running the following command:

   ```bash
   flutter pub add superdeck
   ```

2. Import the `superdeck` package in your Dart code:

   ```dart
   import 'package:superdeck/superdeck.dart';
   ```

3. Initialize SuperDeck and run the app:

   ```dart
   import 'package:flutter/widgets.dart';
   import 'package:superdeck/superdeck.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SuperDeckApp.initialize();

     runApp(
       SuperDeckApp(
         options: DeckOptions(
           widgets: const {
             'myCustomWidget': MyCustomWidgetDefinition(),
           },
         ),
       ),
     );
   }

   class MyCustomWidgetDefinition extends WidgetDefinition<Map<String, Object?>> {
     const MyCustomWidgetDefinition();

     @override
     Map<String, Object?> parse(Map<String, Object?> args) => args;

     @override
     Widget build(BuildContext context, Map<String, Object?> args) {
       final property = args['property'] as String? ?? '';
       return CustomWidget(property: property);
     }
   }
   ```

4. Create a `slides.md` file at the root of your project.

5. Configure your `pubspec.yaml` file to include the necessary assets:

   ```yaml
   flutter:
     assets:
       - assets/
       - slides.md
   ```

6. Configure your app (if needed):

   MacOS

   Change your `Release.entitlements`

   ```xml
   <dict>
      <key>com.apple.security.app-sandbox</key>
      <false/>
      <key>com.apple.security.network.client</key>
      <true/>
   </dict>
   ```

   Change `DebugProfile.entitlements`

   ```xml
   <dict>
      <key>com.apple.security.app-sandbox</key>
      <false/>
      <key>com.apple.security.cs.allow-jit</key>
      <true/>
      <key>com.apple.security.network.server</key>
      <true/>
      <key>com.apple.security.network.client</key>
      <true/>
   </dict>
   ```

7. Start building your slides using the new block-based syntax in your `slides.md` file.

## Core Concepts

SuperDeck has evolved into a block-based presentation system where each slide is composed of sections and blocks that can be arranged in various layouts.

### Slides

A slide is the basic unit of a presentation. Each slide is separated by `---` in your markdown file.

### Blocks

Blocks are the building components of a slide. There are several types of blocks:

#### Section Block (`@section`)

Sections are containers that hold other blocks. You can have multiple sections in a slide.

```markdown
@section {
  flex: 2
}
```

Options:
- `flex`: Controls how much space the section takes relative to other sections (default: 1)
- `align`: Controls the alignment of content within the section
- `scrollable`: Whether the section should be scrollable (default: false)

#### Column Block (`@column`)

Columns are used to display markdown content. You can have multiple columns in a section.

```markdown
@column {
  align: center
  flex: 2
}

# My Content Here

- Point 1
- Point 2
```

Options:
- `flex`: Controls how much space the column takes relative to other columns (default: 1)
- `align`: Controls the alignment of content within the column
- `scrollable`: Whether the column should be scrollable (default: false)

#### Image Block (via Markdown syntax)

Images can be included using standard markdown syntax with additional class annotations.

```markdown
![image_description](https://example.com/image.png) {.cover}
```

Available classes:
- `.cover`: Image will cover the container
- `.contain`: Image will be contained in the container
- `.fill`: Image will fill the container
- `.fitWidth`: Image will fit the width of the container
- `.fitHeight`: Image will fit the height of the container

#### DartPad Block (`@dartpad`)

Embeds a DartPad instance in your slide.

```markdown
@dartpad {
  id: dartpad-id-here
  theme: dark
  embed: true
  run: true
}
```

Options:
- `id`: The ID of the DartPad snippet (required)
- `theme`: The theme to use (dark or light)
- `embed`: Whether to embed the DartPad (default: true)
- `run`: Whether to run the code automatically (default: true)

#### Widget Block (Custom Widgets)

You can use custom widgets that you've registered with SuperDeck.

```markdown
@myCustomWidget {
  property: value
  anotherProperty: anotherValue
}
```

### Content Alignment

You can align content within sections and columns:

```markdown
@column {
  align: center_right
}
```

Available alignment options:
- `topLeft`
- `topCenter`
- `topRight`
- `centerLeft`
- `center`
- `centerRight`
- `bottomLeft`
- `bottomCenter`
- `bottomRight`

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

This content takes up less space due to default flex value of 1.

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

## SuperDeck App Options

### `DeckOptions`

When initializing SuperDeck, you can customize its behavior with various options:

```dart
SuperDeckApp(
  options: DeckOptions(
    // Optional: style overrides (merged on top of defaultSlideStyle)
    baseStyle: SlideStyle(),
    styles: {
      'accentStyle': SlideStyle(),
      'specialStyle': SlideStyle(),
    },

    // Custom widgets (registered by name)
    widgets: const {
      'customWidget': MyCustomWidgetDefinition(),
    },

    // Optional: slide chrome (header/footer/background)
    parts: const SlideParts(),

    debug: false,
  ),
)
```

Options include:
- `baseStyle`: The base style for all slides
- `widgets`: Custom widgets that can be referenced in slides
- `styles`: Custom styles that can be applied to slides
- `parts`: Parts that can be applied to all slides (header, footer, background)
- `debug`: Whether to enable debug mode

### Custom Widgets

You can register custom widgets that can be referenced in your slides:

```dart
widgets: const {
  'twitter': TwitterWidgetDefinition(),
},
```

Then in your markdown:

```markdown
@twitter {
  username: username
  tweetId: 1234567890
}
```

### Generated Assets

SuperDeck can handle various types of assets:

- PNG, JPEG, GIF, WEBP, SVG image formats
- Auto-generated thumbnails
- Mermaid diagram renderings

## Styles and Customization

SuperDeck provides flexible styling options through its styling system:

```dart
baseStyle: SlideStyle(),
styles: {
  'announcement': SlideStyle(),
  'quote': SlideStyle(),
},
```

You can apply these styles to your slides or elements using class annotations:

```markdown
# My Styled Title {.announcement}

> This is a quote {.quote}
```

## Slide Parts

Slide parts allow you to add consistent elements to all slides:

```dart
parts: SlideParts(
  header: CustomHeaderPart(),
  footer: CustomFooterPart(),
  background: CustomBackgroundPart(),
),
```

Each part can be customized with your own widget implementation.

## API Reference

### Block Model

The `Block` class is the base class for all block types:

- `SectionBlock`: Container for organizing blocks horizontally
- `ContentBlock`: Displays markdown content (used by `@column`)
- `WidgetBlock`: Embeds Flutter widgets (including built-in widgets like `image`, `dartpad`, `qrcode`, `mermaid`)

### Asset Model

The `GeneratedAsset` class represents assets used in presentations:

- Image assets (PNG, JPEG, GIF, WEBP, SVG)
- Thumbnails
- Mermaid diagrams

### Slide Model

The `Slide` class represents a single slide in the presentation:

- `key`: Unique identifier for the slide
- `options`: Options for the slide (title, style, etc.)
- `sections`: List of section blocks in the slide
- `comments`: List of comments in the slide

## Advanced Features

### Code Highlighting

Code blocks are automatically highlighted based on the language:

```markdown
```dart
void main() {
  print('Hello, world!');
}
``` {.code}
```

The `.code` class ensures proper formatting and syntax highlighting.

### Animations

You can add simple animations to elements:

```markdown
# This title will animate {.animate}
```

### Notes and Alerts

SuperDeck supports note and alert syntax:

```markdown
> [!NOTE]
> This is a note.

> [!WARNING]
> This is a warning.

> [!CAUTION]
> This is a caution.
```
