
![Superdeck logo](./assets/logo-dark.png#gh-dark-mode-only)
![Superdeck logo](./assets/logo-light.png#gh-light-mode-only)

SuperDeck enables you to craft visually appealing and interactive presentations directly within your Flutter apps, using the simplicity and power of Markdown.

![Screenshot](https://github.com/leoafarias/superdeck/assets/435833/42ec88e9-d3d9-4c52-bbf9-5a2809cca257)

### [View demo here](https://superdeck-dev.web.app)

### [Example code](https://github.com/leoafarias/superdeck/blob/main/example/slides.md)

## Getting Started

Follow these steps to integrate SuperDeck into your Flutter project:

1. Install the `superdeck` package by running the following command:

   ```bash
   flutter pub add superdeck
   ```

2. Import the `superdeck` package in your Dart code:

   ```dart
   import 'package:superdeck_core/superdeck_core.dart';
   ```

3. Initialize SuperDeck and run the app.

   ```dart
   void main() {
     runApp(const SuperDeckApp());
   }
   ```

4. Create a `slides.md` file at the root of your project.

5. Configure your `pubspec.yaml` file to include the necessary assets:

   ```yaml
   flutter:
     assets:
       - assets/
       - assets/images/
   ```

   The `assets` directory is used to slide and asset references, while the `assets/images` directory is specifically used for storing images used in your presentations.

6. Configure your app

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

7. Start building your slides in the `slides.md` file using Markdown syntax and SuperDeck's slide templates and configurations.

### SuperDeck Options

#### `style`

SuperDeck provides a robust styling system by leveraging [Mix](https://fluttermix.com), This allows a complete control by creating endless possibility of defining styling every element in teh slide, and also creating `style variants`.

#### `examples`

These are widget examples that can be referenced in the slide. You can read more about how to reference these examples in the [Widget Template](#widget-template) section.

```dart
SuperDeckApp(
   style: style,
   examples: [
      Example(
         name: 'demo',
         builder: (args) {
            return CustomWidget();
         },
      ),
   ],
);
```

### Shared Slide Options

Some shared options can be applied by adding them to a `superdeck.yaml` file in the root of your project. These options will be applied to all slides unless overridden by slide-specific options.

### Slide Options

The following options are available for configuring each slide. All options are optional.

**Shared Options**
Some shared options can be applied by adding them to a `superdeck.yaml` file in the root of your project. These options will be applied to all slides unless overridden by slide-specific options.

#### `title`

The title of the slide.

#### `background`

The background image that will be displayed on the slide. You can use a URL or a local asset path.

#### `content`

The markdown content of the slide. This is where you write the main content of the slide using Markdown syntax.

- `alignment`: The alignment of the slide content.
- `flex`: The flex value of the slide content. This determines how much space the content occupies relative to other content on the slide.

#### `style`

This is the style variants that will be applied to the slide. You can define style variants by using `Mix` and pass them to the `SuperDeck` constructor.

#### `transition`

The transition effect to be applied when navigating to the slide.

- `type`: The type of transition effect.
- `duration`: The duration of the transition effect in milliseconds.
- `delay`: The delay before the transition effect starts in milliseconds.
- `curve`: The curve of the transition effect.

#### `layout`

Selects a slide layout template. Available options include: `simple`, `two_column`, `two_column_header`, `image`, and `widget`.

## Templates

SuperDeck provides a diverse collection of templates, each designed to meet different presentation needs. From simple text slides to complex layouts with images and columns, you can easily find the right template for your content.

### Simple Template (default)

A straightforward template for your presentations.

```markdown
---
background: https://source.unsplash.com/random/900×700/?landscape
---

# Introduction to SuperDeck

Create **engaging**, **customizable** presentations within your Flutter app.
```

### Two-Column Template

Ideal for presenting comparative or complementary information side by side.

```markdown
---
layout: two_column
---

::left::

# Product A
- Feature 1
- Feature 2

::right::

# Product B
- Feature X
- Feature Y
```

#### Sections

- `::left::`: The content that will be placed in the left column.
- `::right::`: The content that will be placed in the right column.

If the first tag that is found is `::right::` everything before this tag will be placed on the `::left::` section.

You can control the content options for each section on the front matter of the slide.

```markdown
sections:
   left:
      flex: 2
      alignment: center_left
   right:
      flex: 1
      alignment: center_right
```

Read more about on the [content options](#content) section.

### Two-Column Header Template

Similar to the two-column template, but with an additional header section at the top of the slide.

```markdown
---
layout: two_column_header
---

::header::

# Product Comparison

::left::

## Product A
- Feature 1
- Feature 2
- Feature 3

::right::

## Product B
- Feature X
- Feature Y
- Feature Z
```

#### Sections

- `::header::`: The content that will be placed in the header section.
- `::left::`: The content that will be placed in the left column.
- `::right::`: The content that will be placed in the right column.

If the first tag that is found is `::left::`, everything before this tag will be placed in the `::header::` section.

You can control the content options for each section in the front matter of the slide.

```markdown
sections:
   header:
      flex: 2
      alignment: top_right
   left:
      flex: 2
      alignment: center_left
   right:
      flex: 1
      alignment: center_right
```

Keep in mind that you can also control the flex of the `left` and `right` sections by using the `content` property.

Read more about it in the [content options](#content) section.

### Image Template

Display an image alongside the slide content.

```markdown
---
layout: image
options:
  src: https://source.unsplash.com/random/900×700/?nature
  fit: cover
  position: left
---

# Key Features

- Innovative design
- User-friendly
- Energy-efficient
```

The `options` property specifies the image to be displayed. It has the following sub-options:

- `src`: The URL or path to the image file.
- `fit`: How the image should be fitted within the slide.
- `position`: The position of the image relative to the slide content.

### Widget Template

Embed a custom widget within the slide.

```markdown
---
layout: widget
options:
   name: demo
   position: center
   flex: 1
   args:
      customArg: value
      customArg2: value2
---

# Custom Widget

This slide contains a custom widget.
```

The `options` property specifies the widget to be embedded. It has the following sub-options:

- `name`: The name of the widget.
- `position`: The position of the widget relative to the slide content.
- `flex`: The flex value of the widget.
- `args`: Additional arguments to be passed to the widget.
