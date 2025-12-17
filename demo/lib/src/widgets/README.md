# Demo Widgets for Superdeck

This directory contains auto-registered widgets that can be used directly in your Superdeck presentations without any configuration.

## Architecture

### Files

- **`demo_widgets.dart`** - Main registry that exports all demo widgets
- **`font_config.dart`** - Font configurations for consistent typography across demos

### How It Works

1. Example widgets from `../examples/` are imported with namespace aliases
2. Each is wrapped in `_DemoWrapper` to keep it compact and centered
3. The `demoWidgets` getter returns a complete map ready for `DeckOptions.widgets`
4. In `main.dart`, we spread `...demoWidgets` into the widgets map

## Available Widgets

### Mix Examples

These demonstrate the Mix styling system:

#### `@mix-simple-box`
Basic Box widget with color, size, and border radius.

```markdown
---
### Simple Box Example

@mix-simple-box
```

#### `@mix-variants`
Box with hover and press interactions using Mix variants.

```markdown
---
### Interactive Box

@mix-variants
```

#### `@mix-animation`
Switch animation with implicit and keyframe animations.

```markdown
---
### Animation Example

@mix-animation
```

### Naked UI Examples

These demonstrate headless UI components:

#### `@naked-select`
Fully customizable select/dropdown component with styled options.

```markdown
---
### Select Component

@naked-select
```

### Remix Examples

These demonstrate the Remix design system:

#### `@remix-button`
Button variants (solid, soft, outline) with hover/press states.

```markdown
---
### Button Examples

@remix-button
```

## Adding New Demo Widgets

1. **Create the example** in `../examples/{library}/your_widget.dart`
2. **Import it** in `demo_widgets.dart` with a namespace alias:
   ```dart
   import '../examples/mix/your_widget.dart' as mix_your_widget;
   ```
3. **Register it** in the `demoWidgets` map:
   ```dart
   'mix-your-widget': _SimpleWidgetDefinition(
     (context, args) => _DemoWrapper(
       child: mix_your_widget.YourWidget(),
     ),
   ),
   ```
4. **Use it** in `slides.md`:
   ```markdown
   @mix-your-widget
   ```

## Font Configuration

Each library has its own font family defined in `font_config.dart`:

- **Mix**: Inter (modern, geometric)
- **Naked UI**: Roboto (clean, accessible)
- **Remix**: Poppins (professional)
- **Code**: JetBrains Mono (monospace)

To apply fonts to your widgets, import and use `DemoFonts`:

```dart
import 'font_config.dart';

Text(
  'Example',
  style: DemoFonts.mixFont,
)
```

Or use the font family directly:

```dart
TextStyleMix(
  fontFamily: DemoFonts.mixFontFamily,
  fontSize: 16,
)
```

## Widget Arguments

Demo widgets receive a raw argument map (`Map<String, Object?>`). Most demo widgets ignore args, but you can read values directly:

```dart
'custom-widget': _SimpleWidgetDefinition((context, args) {
  final text = args['text'] as String? ?? 'Hello World';
  final size = (args['size'] as num?)?.toInt() ?? 100;
  final enabled = args['enabled'] as bool? ?? true;

  return YourWidget(text: text, size: size, enabled: enabled);
}),
```

Use in markdown:

```markdown
@custom-widget {
  text: "Hello World"
  size: 150
  enabled: false
}
```

## The Wrapper

`_DemoWrapper` provides:

- **Center** alignment (centers the demo in the slide)
- **Intrinsic sizing** (prevents demos from expanding to fill the whole block)

This eliminates the need for each example to manage layout constraints in every demo widget.
