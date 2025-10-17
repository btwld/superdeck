# Markdown Extensions Architecture

## Overview

SuperDeck uses a **two-stage markdown processing pipeline** that separates build-time parsing from runtime rendering. This architecture enables custom markdown syntax, type-safe domain models, and flexible Flutter widget rendering.

## Architecture

### Two-Stage Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│ Stage 1: Build-Time (packages/builder)                         │
│                                                                 │
│ Markdown File → MarkdownParser → SlideProcessor → Dart Code    │
│                                                                 │
│ - Extract frontmatter                                           │
│ - Parse @block syntax                                           │
│ - Generate domain models                                        │
│ - Output .presentation.dart files                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Stage 2: Runtime (packages/superdeck)                           │
│                                                                 │
│ Domain Models → MarkdownViewer → Builders → Flutter Widgets    │
│                                                                 │
│ - Apply custom syntaxes                                         │
│ - Map elements to builders                                      │
│ - Render styled widgets                                         │
│ - Apply Hero animations                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. Custom Markdown Syntax (Parsing)

Extends the [markdown](https://pub.dev/packages/markdown) package to recognize custom patterns:

- **BlockSyntax** - Block-level elements (headers, code blocks, custom containers)
- **InlineSyntax** - Inline elements (links, images, custom tags)
- **DelimiterSyntax** - Paired delimiters (emphasis, strikethrough)

#### 2. Element Builders (Rendering)

Maps markdown AST nodes to Flutter widgets:

- **MarkdownElementBuilder** - Base class from flutter_markdown_plus
- **Registry Pattern** - `SpecMarkdownBuilders` maps tags to builders
- **Visitor Pattern** - Builders implement `visitText()` and `visitElement*()` methods

#### 3. Domain Models

Type-safe representations of slide content:

- **Slide** - Top-level container
- **Block** - Sealed class for content types (ColumnBlock, ImageBlock, etc.)
- **StyleSpec** - Configuration for visual appearance

## Custom Markdown Elements

### Current Implementations

SuperDeck includes several custom markdown extensions:

#### **Custom Header Syntax** – Hero Animation Tags

Extracts CSS-like tags for Hero animations on ATX (`# Heading`) headers:

```markdown
# Welcome to SuperDeck {.title}
```

**Implementation**:  
- Parser: [packages/superdeck/lib/src/markdown/syntaxes/custom_header_syntax.dart](../packages/superdeck/lib/src/markdown/syntaxes/custom_header_syntax.dart)  
- Shared helper: [packages/core/lib/src/markdown/hero_tag_helpers.dart](../packages/core/lib/src/markdown/hero_tag_helpers.dart)

Only ATX headings participate in hero extraction. Setext underline support was intentionally rolled back to keep the initial scope tight; any future work should continue to delegate parsing to the shared helper so core and Flutter stay aligned.

```dart
final (:content, :tag) = getTagAndContent(rawLine);
final inlineNodes = parser.document.parseInline(content);
final element = md.Element('h$level', inlineNodes);
if (tag != null) {
  element.attributes['hero'] = tag;
}
```

#### **Alert Block Syntax** - GitHub-Style Alerts

Parses GitHub-flavored alert blocks:

```markdown
> [!NOTE]
> This is a note alert
```

**Implementation**: [packages/superdeck/lib/src/markdown/builders/alert_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/alert_element_builder.dart)

```dart
class AlertBlockSyntax extends md.AlertBlockSyntax {
  const AlertBlockSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final type = pattern.firstMatch(parser.current.content)!.group(1)!.toLowerCase();
    parser.advance();
    final childLines = parseChildLines(parser);
    final content = childLines.map((line) => line.content).join('\n');

    final alertElement = md.Element.text('alert', content)
      ..attributes['type'] = type;

    return md.Element('p', [alertElement]);
  }
}
```

#### **Custom Image Syntax** - Hero Tags for Images

Adds optional CSS tags to images:

```markdown
![Logo](assets/logo.png) {.hero-logo}
```

**Implementation**:  
- Parser: [packages/superdeck/lib/src/markdown/syntaxes/custom_image_syntax.dart](../packages/superdeck/lib/src/markdown/syntaxes/custom_image_syntax.dart)  
- Shared helper: [packages/core/lib/src/markdown/hero_tag_helpers.dart](../packages/core/lib/src/markdown/hero_tag_helpers.dart)

The inline parser defers to `consumeLeadingHeroMarker` from the shared helper, which safely scans for `{.tag}` immediately after an image (including `![alt](img.png){.hero}`). When a valid tag is found, the helper returns the tag and consumes the marker plus surrounding whitespace so the braces never leak into the rendered markdown.

> **Registration order:** when composing with `markdown` extension sets, register the hero block syntaxes _before_ the stock ones (e.g., `[...]..createHeroBlockSyntaxes(), ...md.ExtensionSet.gitHubFlavored.blockSyntaxes`). This keeps `HeroFencedCodeBlockSyntax` ahead of `FencedCodeBlockSyntax` so fenced code retains its hero attributes.

### Widget Builders

Each markdown element type has a corresponding builder:

#### **TextElementBuilder** - Text & Headings

**File**: [packages/superdeck/lib/src/markdown/builders/text_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/text_element_builder.dart)

Renders text with Hero animation support:

```dart
class TextElementBuilder extends MarkdownElementBuilder {
  final StyleSpec<TextSpec> styleSpec;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final (:tag, :content) = getTagAndContent(text.text);

    Widget result = StyledText(content, styleSpec: styleSpec);

    if (tag != null && !slide.isExporting) {
      result = buildElementHero<TextElement>(
        tag: tag,
        child: result,
        buildFlight: (context, from, to, t) => /* animation */,
      );
    }

    return result;
  }
}
```

#### **CodeElementBuilder** - Code Blocks

**File**: [packages/superdeck/lib/src/markdown/builders/code_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/code_element_builder.dart)

Renders syntax-highlighted code:

```dart
class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return StyleSpecBuilder<CodeSpec>(
      styleSpec: styleSpec,
      builder: (context, spec) {
        final language = _extractLanguage(element.attributes);
        return CodeBlockWidget(
          code: element.textContent,
          language: language,
          spec: spec,
        );
      },
    );
  }
}
```

#### **ImageElementBuilder** - Images

**File**: [packages/superdeck/lib/src/markdown/builders/image_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/image_element_builder.dart)

Renders images with Hero support:

```dart
class ImageElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'];
    final heroTag = element.attributes['hero'];

    return StyleSpecBuilder<ImageSpec>(
      styleSpec: styleSpec,
      builder: (context, spec) {
        Widget image = ImageWidget(src: src, spec: spec);

        if (heroTag != null) {
          image = buildElementHero<ImageElement>(
            tag: heroTag,
            child: image,
          );
        }

        return image;
      },
    );
  }
}
```

#### **AlertElementBuilder** - Alert Blocks

**File**: [packages/superdeck/lib/src/markdown/builders/alert_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/alert_element_builder.dart)

Renders alerts with icons and type-specific styling:

```dart
class AlertElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final type = element.attributes['type'] ?? 'note';

    return StyleSpecBuilder<MarkdownAlertSpec>(
      styleSpec: styleSpec,
      builder: (context, spec) {
        final typeSpec = _getTypeSpec(spec, type);
        return AlertWidget(
          content: element.textContent,
          type: type,
          spec: typeSpec,
        );
      },
    );
  }
}
```

### Builder Registry

**File**: [packages/superdeck/lib/src/markdown/markdown_element_builders_registry.dart](../packages/superdeck/lib/src/markdown/markdown_element_builders_registry.dart)

All builders are registered in `SpecMarkdownBuilders`:

```dart
class SpecMarkdownBuilders {
  final SlideSpec spec;

  SpecMarkdownBuilders(this.spec);

  // Custom syntaxes
  final List<md.BlockSyntax> blockSyntaxes = [
    const CustomHeaderSyntax(),
    const AlertBlockSyntax(),
  ];

  final List<md.InlineSyntax> inlineSyntaxes = [
    CustomImageSyntax(),
  ];

  // Element builders
  late final Map<String, MarkdownElementBuilder> builders = {
    'h1': TextElementBuilder(spec.h1),
    'h2': TextElementBuilder(spec.h2),
    'h3': TextElementBuilder(spec.h3),
    'p': TextElementBuilder(spec.p),
    'code': CodeElementBuilder(spec.code),
    'img': ImageElementBuilder(spec.image),
    'alert': AlertElementBuilder(spec.alert),
    'li': TextElementBuilder(spec.list.text),
  };
}
```

## Creating Custom Elements

### The 4-Step Pattern

Follow this pattern to add new custom markdown widgets:

#### **Step 1: Define Domain Model** (Optional)

If you need a custom block type at build-time:

```dart
// packages/core/lib/src/models/block_model.dart

@MappableClass(discriminatorValue: CustomBlock.key)
class CustomBlock extends Block with CustomBlockMappable {
  static const key = 'custom';

  final String customProperty;

  CustomBlock({required this.customProperty}) : super(type: key);

  static final schema = Ack.object({
    'type': Ack.string(),
    'customProperty': Ack.string(),
  });
}
```

#### **Step 2: Create Custom Syntax** (Optional)

If you need new markdown patterns:

```dart
// packages/superdeck/lib/src/markdown/builders/custom_element_builder.dart

class CustomBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^:::custom\s+(.+)$');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final customData = match.group(1)!;

    parser.advance();

    // Parse child lines
    final childLines = <md.Line>[];
    while (!parser.isDone && !parser.current.content.startsWith(':::')) {
      childLines.add(parser.current);
      parser.advance();
    }
    if (!parser.isDone) parser.advance(); // Skip closing :::

    // Recursively parse children
    final children = md.BlockParser(childLines, parser.document).parseLines();

    return md.Element('custom-tag', children)
      ..attributes['data'] = customData;
  }
}
```

#### **Step 3: Create Element Builder** (Required)

Map the element to a Flutter widget:

```dart
// packages/superdeck/lib/src/markdown/builders/custom_element_builder.dart

class CustomElementBuilder extends MarkdownElementBuilder {
  final StyleSpec<CustomSpec> styleSpec;

  CustomElementBuilder([this.styleSpec = const StyleSpec(spec: CustomSpec())]);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return StyleSpecBuilder<CustomSpec>(
      styleSpec: styleSpec,
      builder: (context, spec) {
        final block = BlockData.of(context);
        final customData = element.attributes['data'];

        return CustomWidget(
          data: customData,
          content: element.textContent,
          spec: spec,
          size: block.size,
        );
      },
    );
  }
}
```

#### **Step 4: Register in SpecMarkdownBuilders** (Required)

Add to the builder registry:

```dart
// packages/superdeck/lib/src/markdown/markdown_element_builders_registry.dart

class SpecMarkdownBuilders {
  final List<md.BlockSyntax> blockSyntaxes = [
    const CustomHeaderSyntax(),
    const AlertBlockSyntax(),
    CustomBlockSyntax(), // ← Add custom syntax
  ];

  late final Map<String, MarkdownElementBuilder> builders = {
    'h1': TextElementBuilder(spec.h1),
    'code': CodeElementBuilder(spec.code),
    'custom-tag': CustomElementBuilder(spec.custom), // ← Add builder
  };
}
```

### Best Practices

#### **For BlockSyntax**

✅ **Extend existing syntax** when enhancing built-in elements:
```dart
class CustomHeaderSyntax extends md.HeaderSyntax { ... }
```

✅ **Use `parseChildLines()`** for nested content:
```dart
final childLines = parseChildLines(parser);
final children = md.BlockParser(childLines, parser.document).parseLines();
```

✅ **Always advance the parser** after consuming lines:
```dart
parser.advance();
```

✅ **Check `parser.isDone`** before accessing `parser.current`:
```dart
while (!parser.isDone && !parser.current.content.startsWith(':::')) {
  childLines.add(parser.current);
  parser.advance();
}
```

#### **For InlineSyntax**

✅ **Provide start character** for optimization:
```dart
CustomInlineSyntax() : super(pattern, startCharacter: $colon);
```

✅ **Use named groups** in regex for clarity:
```dart
static const _pattern = r'!\[(.*?)\]\((.*?)\)(?:\s*\{\.([^\}]+)\})?';
//                           ^^^       ^^^           ^^^^^^^^^^^
//                           alt      url            optional tag
```

✅ **Handle optional groups** gracefully:
```dart
final tag = match.group(3); // May be null
if (tag != null) {
  element.attributes['hero'] = tag;
}
```

✅ **Return true** for auto-advance, **false** if advancing manually:
```dart
@override
bool onMatch(md.InlineParser parser, Match match) {
  parser.addNode(element);
  return true; // Parser auto-advances by match.length
}
```

#### **For Element Builders**

✅ **Use StyleSpecBuilder** for spec-driven styling:
```dart
return StyleSpecBuilder<CustomSpec>(
  styleSpec: styleSpec,
  builder: (context, spec) => CustomWidget(spec: spec),
);
```

✅ **Access context via InheritedWidgets**:
```dart
final block = BlockData.of(context);
final slide = SlideConfiguration.of(context);
```

✅ **Conditional Hero wrapping** based on export mode:
```dart
if (heroTag != null && !slide.isExporting) {
  widget = buildElementHero(tag: heroTag, child: widget);
}
```

✅ **Filter standalone CSS tags** in text:
```dart
final (:tag, :content) = getTagAndContent(text.text);
// Only render content, use tag for Hero
```

#### **For Custom Elements**

✅ **Use kebab-case** for custom tag names:
```dart
md.Element('hero-slide', children)    // Good
md.Element('heroSlide', children)     // Avoid
```

✅ **Store metadata** in attributes:
```dart
element.attributes['data-id'] = '123';
element.attributes['data-type'] = 'callout';
```

✅ **Use `Element.text()`** for single text child:
```dart
md.Element.text('custom', content)
  ..attributes['type'] = type;
```

✅ **Use `Element.empty()`** for self-closing elements:
```dart
final img = md.Element.empty('img');
img.attributes['src'] = url;
```

## Extension Points Summary

| Extension Point | Purpose | Extend | Output |
|----------------|---------|--------|--------|
| **BlockSyntax** | Parse block-level elements | `md.BlockSyntax` | `md.Element` nodes |
| **InlineSyntax** | Parse inline elements | `md.InlineSyntax` | `md.Element` or `md.Text` |
| **DelimiterSyntax** | Parse paired delimiters | `md.DelimiterSyntax` | Nested `md.Element` |
| **MarkdownElementBuilder** | Render to Flutter widgets | `MarkdownElementBuilder` | `Widget` |
| **ExtensionSet** | Bundle syntaxes | Create `md.ExtensionSet` | Configuration |

## Testing Custom Elements

### Unit Tests for Syntax

Test parsing logic:

```dart
void main() {
  group('CustomBlockSyntax', () {
    test('parses custom block with attributes', () {
      final markdown = '''
:::custom my-data
Content here
:::
''';

      final document = md.Document(
        blockSyntaxes: [CustomBlockSyntax()],
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final nodes = document.parseLines(markdown.split('\n'));

      expect(nodes, hasLength(1));
      expect(nodes.first, isA<md.Element>());

      final element = nodes.first as md.Element;
      expect(element.tag, 'custom-tag');
      expect(element.attributes['data'], 'my-data');
    });
  });
}
```

### Widget Tests for Builders

Test widget rendering:

```dart
void main() {
  testWidgets('CustomElementBuilder renders widget', (tester) async {
    final element = md.Element.text('custom-tag', 'Test content')
      ..attributes['data'] = 'test-data';

    final builder = CustomElementBuilder();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => builder.visitElementAfter(element, null)!,
        ),
      ),
    );

    expect(find.text('Test content'), findsOneWidget);
    expect(find.byType(CustomWidget), findsOneWidget);
  });
}
```

## Reference Files

### Core Package
- [markdown_json.dart](../packages/core/lib/markdown_json.dart) - AST generation utilities
- [block_model.dart](../packages/core/lib/src/models/block_model.dart) - Domain models

### Builder Package
- [markdown_parser.dart](../packages/builder/lib/src/parsers/markdown_parser.dart) - Build-time parsing
- [block_parser.dart](../packages/builder/lib/src/parsers/block_parser.dart) - Custom @block syntax

### SuperDeck Package
- [markdown_element_builders.dart](../packages/superdeck/lib/src/markdown/markdown_element_builders_registry.dart) - Builder registry & custom syntaxes
- [text_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/text_element_builder.dart) - Text & heading builder
- [code_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/code_element_builder.dart) - Code block builder
- [image_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/image_element_builder.dart) - Image builder
- [alert_element_builder.dart](../packages/superdeck/lib/src/markdown/builders/alert_element_builder.dart) - Alert builder
- [hero_element.dart](../packages/superdeck/lib/src/ui/widgets/hero_element.dart) - Hero animation helpers
- [markdown_viewer.dart](../packages/superdeck/lib/src/rendering/blocks/markdown_viewer.dart) - Markdown rendering entry point

## Additional Resources

- [markdown package documentation](https://pub.dev/packages/markdown)
- [flutter_markdown_plus package](https://pub.dev/packages/flutter_markdown_plus)
- [CommonMark Spec](https://spec.commonmark.org/)
- [GitHub Flavored Markdown Spec](https://github.github.com/gfm/)
