![Superdeck logo](./assets/logo-dark.png#gh-dark-mode-only)
![Superdeck logo](./assets/logo-light.png#gh-light-mode-only)

# SuperDeck

SuperDeck enables you to craft visually appealing and interactive presentations directly within your Flutter apps, using the simplicity and power of Markdown.

![Screenshot](https://github.com/leoafarias/superdeck/assets/435833/42ec88e9-d3d9-4c52-bbf9-5a2809cca257)

### [View demo here](https://superdeck-dev.web.app)

### [Example code](https://github.com/leoafarias/superdeck/blob/main/example/slides.md)

## Getting Started

Follow these steps to integrate SuperDeck into your Flutter project:

1. Install the CLI to set up your project:

   ```bash
   dart pub global activate superdeck_cli
   ```

2. In your Flutter project, run the setup command:

   ```bash
   superdeck setup
   ```

   This command will:
   - Configure your pubspec.yaml with required assets
   - Set up macOS entitlements if applicable
   - Create a basic slides.md file if none exists
   - Set up a custom index.html for web with loading indicator

3. Add the `superdeck` package to your project:

   ```bash
   flutter pub add superdeck
   ```

4. Import the package and initialize SuperDeck:

   ```dart
   import 'package:superdeck/superdeck.dart';

   void main() async {
     await SuperDeckApp.initialize();
     runApp(
       MaterialApp(
         title: 'Superdeck',
         debugShowCheckedModeBanner: false,
         home: SuperDeckApp(
           options: DeckOptions(
             baseStyle: BaseStyle(),
             widgets: {
               'twitter': (args) {
                 return TwitterWidget(
                   username: args.getString('username'),
                   tweetId: args.getString('tweetId'),
                 );
               },
             },
             debug: false,
             styles: {
               'announcement': AnnouncementStyle(),
               'quote': QuoteStyle(),
             },
             parts: const SlideParts(
               header: HeaderPart(),
               footer: FooterPart(),
               background: BackgroundPart(),
             ),
           ),
         ),
       ),
     );
   }
   ```

## Block-Based System

SuperDeck uses a powerful block-based system for arranging content in your slides. This provides flexible layouts and composition options.

### Block Types

- `@column` - For text and markdown content
- `@section` - Container for organizing multiple blocks
- `@image` - For displaying images with various options
- `@dartpad` - Embed DartPad examples
- `@widget` - Embed custom widgets with arguments

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

### Custom Alignment Options

Blocks support various alignment options:
- `topLeft`, `topCenter`, `topRight`
- `centerLeft`, `center`, `centerRight`
- `bottomLeft`, `bottomCenter`, `bottomRight`

### Flex Property

Use the `flex` property to control relative sizing of blocks:

```markdown
@section
@column {
  flex: 2
}
This column takes up twice the space
@column
Normal sized column
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

## Styling with CSS Classes

You can add CSS classes to your content using the `{.class-name}` syntax:

```markdown
## Styled Heading {.highlight}

![example_image](https://picsum.photos/800/600) {.cover}
```

## SuperDeck Options

SuperDeck provides a robust styling system with the ability to customize the presentation with various options:

```dart
DeckOptions(
  // Base style for all slides
  baseStyle: BaseStyle(),
  
  // Custom widgets available to use in slides
  widgets: {
    'twitter': (args) {
      return TwitterWidget(
        username: args.getString('username'),
        tweetId: args.getString('tweetId'),
      );
    },
  },
  
  // Debug mode to help visualize slide structure
  debug: false,
  
  // Custom styles for specific slide types
  styles: {
    'announcement': AnnouncementStyle(),
    'quote': QuoteStyle(),
  },
  
  // Slide parts for consistent layouts
  parts: const SlideParts(
    header: HeaderPart(),
    footer: FooterPart(),
    background: BackgroundPart(),
  ),
)
```

## Configuration

You can configure SuperDeck by creating a `superdeck.yaml` file in the root of your project. This allows you to set default options for all slides.

## For More Details

Check out the example slides and explore the API documentation for advanced usage scenarios.
