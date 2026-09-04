import 'package:superdeck_core/superdeck_core.dart';

import 'comment_parser.dart';
import 'directive_names.dart';

/// Serializes [Slide] models back into SuperDeck-flavored Markdown.
///
/// This is the inverse of the parsing pipeline ([MarkdownParser] +
/// [SectionParser] + [BlockParser] + [TagTokenizer] + [CommentParser]).
///
/// Round-tripping `parse(serialize(slides))` reproduces the slides
/// structurally — options, section/block layout (flex/align/spacing/scrollable),
/// widget names + args, markdown content, and comments — modulo the
/// content-hash [Slide.key] (regenerated on parse) and insignificant
/// whitespace inside content blocks.
///
/// Note: deck-level concerns that have no Markdown representation (e.g. an
/// AI-generated color/font theme) are intentionally NOT serialized here; the
/// host applies those out-of-band via `DeckOptions`.
class SlideSerializer {
  const SlideSerializer();

  static final _identifierPattern = RegExp(r'^[\w-]+$');
  static final _directiveLinePattern = RegExp(r'^\s*@[\w-]+');

  /// Serializes a list of [slides] into a single Markdown document.
  String serialize(List<Slide> slides) {
    if (slides.isEmpty) return '';
    final buffer = StringBuffer();
    for (final slide in slides) {
      _writeSlide(buffer, slide);
    }
    return '${buffer.toString().trim()}\n';
  }

  /// Serializes a single [slide] (without a trailing newline).
  String serializeSlide(Slide slide) {
    final buffer = StringBuffer();
    _writeSlide(buffer, slide);
    return buffer.toString().trim();
  }

  void _writeSlide(StringBuffer buffer, Slide slide) {
    // The opening `---` doubles as the slide separator. When the slide has
    // frontmatter, the matching close `---` follows the YAML body.
    buffer.writeln('---');
    final frontmatter = _frontmatter(slide.options);
    if (frontmatter != null) {
      buffer.write(frontmatter);
      buffer.writeln('---');
    }
    buffer.writeln();

    final body = _body(slide).trim();
    if (body.isNotEmpty) {
      buffer.writeln(body);
      buffer.writeln();
    }

    // Comments parsed from markdown remain embedded in the content block, so
    // [Slide.comments] mirrors them. Only emit comments that are not already
    // represented in the body (e.g. programmatically attached notes), so a
    // markdown round-trip doesn't duplicate them.
    final embedded = const CommentParser().parse(body).toSet();
    final extra = slide.comments.where((c) => !embedded.contains(c)).toList();
    final comments = _comments(extra);
    if (comments.isNotEmpty) {
      buffer.writeln(comments);
      buffer.writeln();
    }
  }

  // ---------------------------------------------------------------------------
  // Frontmatter
  // ---------------------------------------------------------------------------

  /// Returns the YAML frontmatter body (each `key: value` on its own line,
  /// trailing newline included), or null when there are no options to emit.
  String? _frontmatter(SlideOptions? options) {
    if (options == null) return null;

    final entries = <MapEntry<String, Object?>>[];
    if (options.title != null) entries.add(MapEntry('title', options.title));
    if (options.style != null) entries.add(MapEntry('style', options.style));
    if (options.layout != null) {
      entries.add(MapEntry('layout', options.layout!.name));
    }
    if (options.template != null) {
      entries.add(MapEntry('template', options.template));
    }
    entries.addAll(options.args.entries);

    if (entries.isEmpty) return null;

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln('${entry.key}: ${_flowValue(entry.value)}');
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Sections & blocks
  // ---------------------------------------------------------------------------

  String _body(Slide slide) {
    final sections = slide.sections;
    if (sections.isEmpty) return '';

    // Implicit single section with a single default content block round-trips
    // as plain markdown with no directives.
    if (_isImplicitSection(sections)) {
      final block = sections.first.blocks.first as ContentBlock;
      return _escapeContent(block.content.trim());
    }

    final buffer = StringBuffer();
    final multipleSections = sections.length > 1;
    for (final section in sections) {
      final needsDirective =
          multipleSections ||
          section.flex != 1 ||
          section.align != null ||
          section.spacing != 0;
      if (needsDirective) {
        buffer.writeln(_directive('section', _sectionOptions(section)));
        buffer.writeln();
      }
      for (final block in section.blocks) {
        _writeBlock(buffer, block);
      }
    }
    return buffer.toString();
  }

  bool _isImplicitSection(List<SectionBlock> sections) {
    if (sections.length != 1) return false;
    final section = sections.first;
    if (section.flex != 1 || section.align != null || section.spacing != 0) {
      return false;
    }
    if (section.blocks.length != 1) return false;
    final block = section.blocks.first;
    return block is ContentBlock &&
        block.flex == 1 &&
        block.align == null &&
        block.margin == null &&
        block.padding == null &&
        !block.scrollable;
  }

  void _writeBlock(StringBuffer buffer, Block block) {
    switch (block) {
      case ContentBlock():
        buffer.writeln(_directive('block', _blockOptions(block)));
        buffer.writeln();
        final content = _escapeContent(block.content.trim());
        if (content.isNotEmpty) {
          buffer.writeln(content);
          buffer.writeln();
        }
      case WidgetBlock():
        final useShorthand =
            _identifierPattern.hasMatch(block.name) &&
            !reservedDirectiveNames.contains(block.name);
        final tag = useShorthand ? block.name : 'widget';
        final options = _blockOptions(block);
        if (!useShorthand) options['name'] = block.name;
        options.addAll(block.args);
        buffer.writeln(_directive(tag, options));
        buffer.writeln();
    }
  }

  Map<String, Object?> _sectionOptions(SectionBlock section) {
    final options = <String, Object?>{};
    if (section.flex != 1) options['flex'] = section.flex;
    if (section.align != null) options['align'] = section.align!.name;
    if (section.spacing != 0) options['spacing'] = section.spacing;
    return options;
  }

  Map<String, Object?> _blockOptions(Block block) {
    final options = <String, Object?>{};
    if (block.flex != 1) options['flex'] = block.flex;
    if (block.align != null) options['align'] = block.align!.name;
    if (block.padding != null) options['padding'] = block.padding!.toJson();
    if (block.margin != null) options['margin'] = block.margin!.toJson();
    if (block.scrollable) options['scrollable'] = true;
    return options;
  }

  // ---------------------------------------------------------------------------
  // Directives & YAML values
  // ---------------------------------------------------------------------------

  /// Renders a `@name` directive with an optional `{ ... }` options block.
  ///
  /// A single non-map option is rendered inline (`@block { padding: 16 }`).
  /// Any other shape uses multiline braces with one option per line, because
  /// comma-separated `key: a, key2: b` on one line is not valid YAML inside
  /// the directive braces.
  String _directive(String name, Map<String, Object?> options) {
    if (options.isEmpty) return '@$name';
    if (options.length == 1) {
      final entry = options.entries.first;
      final value = entry.value;
      if (value is! Map || value.isEmpty) {
        return '@$name { ${entry.key}: ${_directiveValue(value, 1)} }';
      }
    }
    final buffer = StringBuffer('@$name {\n');
    for (final entry in options.entries) {
      buffer.writeln('  ${entry.key}: ${_directiveValue(entry.value, 1)}');
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Formats one directive option value nested at [indentLevel].
  ///
  /// Scalars and lists stay inline; non-empty maps become multiline YAML flow
  /// mappings. Flow-map entries are comma-separated (with a trailing comma)
  /// because a multiline flow mapping without commas is invalid YAML.
  String _directiveValue(Object? value, int indentLevel) {
    if (value is Map && value.isNotEmpty) {
      final entryIndent = '  ' * (indentLevel + 1);
      final closeIndent = '  ' * indentLevel;
      final buffer = StringBuffer('{\n');
      for (final entry in value.entries) {
        final nested = _directiveValue(entry.value, indentLevel + 1);
        buffer.writeln('$entryIndent${entry.key}: $nested,');
      }
      buffer.write('$closeIndent}');
      return buffer.toString();
    }

    return _flowValue(value);
  }

  /// Formats a value inline in YAML flow style.
  String _flowValue(Object? value) {
    if (value == null) return 'null';
    if (value is num) return _numValue(value);
    if (value is bool) return value.toString();
    if (value is List) {
      return '[${value.map(_flowValue).join(', ')}]';
    }
    if (value is Map) {
      final entries = value.entries
          .map((e) => '${e.key}: ${_flowValue(e.value)}')
          .join(', ');
      return '{$entries}';
    }
    return _yamlString(value.toString());
  }

  /// Emits whole-number doubles (e.g. normalized inset edges) as integers so
  /// canonical output reads `top: 12` instead of `top: 12.0`. Both re-parse to
  /// the same normalized value.
  String _numValue(num value) {
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value.toString();
  }

  /// Quotes a string only when bare emission would be ambiguous or re-parse to
  /// a non-string value. Quoting never changes the parsed value, so this is
  /// purely for human-friendly output.
  static final _needsQuotePattern = RegExp('''[:#\\[\\]{}&*!|>'"%@`,]''');

  String _yamlString(String value) {
    if (value.isEmpty) return '""';
    final needsQuote =
        _needsQuotePattern.hasMatch(value) ||
        value != value.trim() ||
        value.contains('\n') ||
        _isYamlKeyword(value) ||
        _looksNumeric(value);
    if (!needsQuote) return value;
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }

  bool _isYamlKeyword(String value) {
    const keywords = {'true', 'false', 'null', 'yes', 'no', 'on', 'off', '~'};
    return keywords.contains(value.toLowerCase());
  }

  bool _looksNumeric(String value) => num.tryParse(value) != null;

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  String _comments(List<String> comments) {
    if (comments.isEmpty) return '';
    return comments.map((comment) => '<!-- $comment -->').join('\n');
  }

  // ---------------------------------------------------------------------------
  // Content escaping
  // ---------------------------------------------------------------------------

  /// Escapes content lines that would otherwise be mistaken for layout
  /// directives. A line like `@foo` (outside a code fence) is emitted as
  /// `_@foo`; the parser restores it via `_updateIgnoredTags`.
  String _escapeContent(String content) {
    if (content.isEmpty) return content;
    final fenced = fencedCodeLines(content);
    final lines = content.split('\n');
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!fenced.contains(i) && _directiveLinePattern.hasMatch(line)) {
        final atIndex = line.indexOf('@');
        result.add('${line.substring(0, atIndex)}_${line.substring(atIndex)}');
      } else {
        result.add(line);
      }
    }

    return result.join('\n');
  }
}
