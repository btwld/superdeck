# Using Custom Fonts in Demo Widgets

This guide shows how to apply custom Google Fonts to each type of widget in the demo.

## Quick Reference

```dart
import 'font_config.dart';

// Get a TextStyle
Text('Hello', style: DemoFonts.mixFont)

// Get just the font family name
TextStyle(fontFamily: DemoFonts.mixFontFamily)
```

## Font Assignments

| Library   | Font Family    | Use Case                    |
|-----------|----------------|-----------------------------|
| Mix       | Inter          | Modern styling system       |
| Naked UI  | Roboto         | Headless components         |
| Remix     | Poppins        | Design system components    |
| Code      | JetBrains Mono | Code blocks and snippets    |

## Examples by Library

### Mix Widgets

Mix uses `TextStyleMix` for styling text. You can set the font family directly:

```dart
import 'package:mix/mix.dart';
import 'font_config.dart';

// Using TextStyler with font
final textStyle = TextStyler().style(TextStyleMix(
  fontFamily: DemoFonts.mixFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w500,
));

// In a Box with text
Box(
  style: BoxStyler().color(Colors.blue),
  child: StyledText(
    'Hello Mix',
    style: textStyle,
  ),
)
```

**Full Example:**

```dart
'mix-custom': (args) => _DemoWrapper(
  child: Box(
    style: BoxStyler()
      .color(Colors.blue)
      .padding(16),
    child: StyledText(
      args.getStringOr('text', 'Mix Demo'),
      style: TextStyler().style(TextStyleMix(
        fontFamily: DemoFonts.mixFontFamily,
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      )),
    ),
  ),
),
```

### Naked UI Widgets

Naked UI uses standard Flutter `TextStyle`:

```dart
import 'package:naked_ui/naked_ui.dart';
import 'font_config.dart';

// Apply to text within components
Text(
  'Select an option',
  style: DemoFonts.nakedFont.copyWith(
    fontSize: 16,
    color: Colors.black87,
  ),
)
```

**Full Example:**

```dart
'naked-custom': (args) => _DemoWrapper(
  backgroundColor: Colors.grey.shade50,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Custom Select',
        style: DemoFonts.nakedFont.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      SimpleSelectExample(),
    ],
  ),
),
```

### Remix Widgets

Remix uses its own style system. You can set font properties through the style API:

```dart
import 'package:remix/remix.dart';
import 'font_config.dart';

// Using RemixButtonStyle with font
RemixButton(
  label: 'Click Me',
  onPressed: () {},
  style: RemixButtonStyle()
    .labelFontFamily(DemoFonts.remixFontFamily)
    .labelFontSize(14)
    .labelFontWeight(FontWeight.w600)
    .labelLetterSpacing(0.3),
)
```

**Full Example:**

```dart
'remix-custom': (args) => _DemoWrapper(
  backgroundColor: Colors.white,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      Text(
        'Remix Buttons',
        style: DemoFonts.headingFont,
      ),
      RemixButton(
        label: args.getStringOr('label', 'Custom Button'),
        onPressed: () {},
        style: RemixButtonStyle()
          .labelFontFamily(DemoFonts.remixFontFamily)
          .labelFontSize(14)
          .labelFontWeight(FontWeight.w600)
          .labelColor(Colors.white)
          .color(Colors.blueAccent.shade700)
          .paddingAll(12)
          .borderRadiusAll(Radius.circular(8)),
      ),
    ],
  ),
),
```

## Overriding Default Fonts

If you want to change the default fonts for all widgets, edit `font_config.dart`:

```dart
class DemoFonts {
  // Change Mix to use Montserrat instead of Inter
  static TextStyle get mixFont => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static String? get mixFontFamily => GoogleFonts.montserrat().fontFamily;
}
```

## Adding Custom Fonts from Assets

If you want to use custom fonts from your assets:

1. **Add font files** to `demo/fonts/`:
   ```
   demo/
     fonts/
       CustomFont-Regular.ttf
       CustomFont-Bold.ttf
   ```

2. **Declare in `pubspec.yaml`**:
   ```yaml
   flutter:
     fonts:
       - family: CustomFont
         fonts:
           - asset: fonts/CustomFont-Regular.ttf
           - asset: fonts/CustomFont-Bold.ttf
             weight: 700
   ```

3. **Use in `font_config.dart`**:
   ```dart
   static const String mixFontFamily = 'CustomFont';

   static TextStyle get mixFont => const TextStyle(
         fontFamily: 'CustomFont',
         fontSize: 16,
         fontWeight: FontWeight.w500,
       );
   ```

## Font Loading Best Practices

Google Fonts are cached automatically after first load. For better performance:

1. **Preload fonts** in `main.dart`:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     // Preload all demo fonts
     await Future.wait([
       GoogleFonts.pendingFonts([
         GoogleFonts.inter(),
         GoogleFonts.roboto(),
         GoogleFonts.poppins(),
         GoogleFonts.jetBrainsMono(),
       ]),
     ]);

     runApp(MyApp());
   }
   ```

2. **Bundle fonts** for offline use (see [google_fonts docs](https://pub.dev/packages/google_fonts#bundling-fonts)).

## Using Different Fonts Per Widget

You can override fonts per widget instance by accepting a `fontFamily` argument:

```dart
'mix-box': (args) {
  final fontFamily = args.getStringOr('font', DemoFonts.mixFontFamily ?? 'Inter');

  return _DemoWrapper(
    child: Box(
      child: StyledText(
        'Custom Font',
        style: TextStyler().style(TextStyleMix(
          fontFamily: fontFamily,
          fontSize: 16,
        )),
      ),
    ),
  );
}
```

Usage in slides:

```markdown
@mix-box {
  font: "Roboto Mono"
}
```

## Typography Scale

For consistent sizing across all demos, consider defining a scale in `font_config.dart`:

```dart
class DemoFonts {
  // Typography scale
  static const double fontSize10 = 10;
  static const double fontSize12 = 12;
  static const double fontSize14 = 14;
  static const double fontSize16 = 16;
  static const double fontSize18 = 18;
  static const double fontSize20 = 20;
  static const double fontSize24 = 24;
  static const double fontSize32 = 32;

  // Font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
```

Then use throughout your widgets:

```dart
TextStyle(
  fontSize: DemoFonts.fontSize16,
  fontWeight: DemoFonts.medium,
)
```
