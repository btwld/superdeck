import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:superdeck_core/markdown_json.dart';
import 'package:test/test.dart';

import 'test_utils/json_snapshot_utils.dart';

final _converter = MarkdownAstConverter(
  extensionSet: md.ExtensionSet.gitHubWeb,
);

/// Comprehensive markdown reference generator that systematically creates
/// JSON output for every possible markdown node type.
///
/// This test generates a complete reference document (`markdown_ref.json`)
/// demonstrating the AST structure for all markdown elements supported by
/// the markdown package v7.3.0 with GitHub Web extensions.
void main() {
  test('Generate comprehensive markdown reference', () {
    final file = File('markdown_ref.json');

    final reference = <String, dynamic>{
      'metadata': <String, dynamic>{}, // populated by writeJsonIfChanged
      'block_elements': <String, dynamic>{},
      'inline_elements': <String, dynamic>{},
      'special_cases': <String, dynamic>{},
      'complex_nested': <String, dynamic>{},
      'metadata_examples': <String, dynamic>{},
    };

    // Generate all categories systematically
    _generateHeadings(reference['block_elements'] as Map<String, dynamic>);
    _generateParagraphs(reference['block_elements'] as Map<String, dynamic>);
    _generateBlockquotes(reference['block_elements'] as Map<String, dynamic>);
    _generateLists(reference['block_elements'] as Map<String, dynamic>);
    _generateCodeBlocks(reference['block_elements'] as Map<String, dynamic>);
    _generateTables(reference['block_elements'] as Map<String, dynamic>);
    _generateAlerts(reference['block_elements'] as Map<String, dynamic>);
    _generateHorizontalRules(
      reference['block_elements'] as Map<String, dynamic>,
    );

    _generateTextFormatting(
      reference['inline_elements'] as Map<String, dynamic>,
    );
    _generateLinks(reference['inline_elements'] as Map<String, dynamic>);
    _generateImages(reference['inline_elements'] as Map<String, dynamic>);
    _generateInlineCode(reference['inline_elements'] as Map<String, dynamic>);
    _generateLineBreaks(reference['inline_elements'] as Map<String, dynamic>);
    _generateColorSwatches(
      reference['inline_elements'] as Map<String, dynamic>,
    );
    _generateEmoji(reference['inline_elements'] as Map<String, dynamic>);
    _generateInlineHtml(reference['inline_elements'] as Map<String, dynamic>);

    _generateEmptyElements(reference['special_cases'] as Map<String, dynamic>);
    _generateElementsWithAttributes(
      reference['special_cases'] as Map<String, dynamic>,
    );
    _generateEscapedCharacters(
      reference['special_cases'] as Map<String, dynamic>,
    );

    _generateNestedStructures(
      reference['complex_nested'] as Map<String, dynamic>,
    );
    _generateFootnotes(reference['complex_nested'] as Map<String, dynamic>);

    _generateMetadataExamples(
      reference['metadata_examples'] as Map<String, dynamic>,
    );

    final written = writeJsonIfChanged(
      file: file,
      reference: reference,
      buildMetadata: (timestamp) => {
        'generated': timestamp,
        'markdown_package_version': '7.3.0',
        'extension_set': 'gitHubWeb',
        'description':
            'Comprehensive reference of all markdown AST node types and structures',
      },
    );

    if (written) {
      print(
        '✅ Generated markdown_ref.json with ${reference.length} categories',
      );
    } else {
      print(
        '✓ markdown_ref.json is up to date (${reference.length} categories)',
      );
    }
  });
}

/// Helper to convert markdown and store in reference with description
void _convertAndStore(
  Map<String, dynamic> category,
  String key,
  String markdown, {
  String? description,
  bool includeMetadata = false,
}) {
  category[key] = {
    'description': description ?? key,
    'markdown': markdown,
    'ast': _converter.toMap(markdown, includeMetadata: includeMetadata),
  };
}

// ============================================================================
// BLOCK ELEMENTS
// ============================================================================

void _generateHeadings(Map<String, dynamic> block) {
  block['headings'] = <String, dynamic>{};
  final headings = block['headings'] as Map<String, dynamic>;

  // ATX headings (# syntax)
  _convertAndStore(
    headings,
    'h1_atx',
    '# Heading Level 1',
    description: 'Level 1 heading using ATX syntax',
  );

  _convertAndStore(
    headings,
    'h2_atx',
    '## Heading Level 2',
    description: 'Level 2 heading using ATX syntax',
  );

  _convertAndStore(
    headings,
    'h3_atx',
    '### Heading Level 3',
    description: 'Level 3 heading using ATX syntax',
  );

  _convertAndStore(
    headings,
    'h4_atx',
    '#### Heading Level 4',
    description: 'Level 4 heading using ATX syntax',
  );

  _convertAndStore(
    headings,
    'h5_atx',
    '##### Heading Level 5',
    description: 'Level 5 heading using ATX syntax',
  );

  _convertAndStore(
    headings,
    'h6_atx',
    '###### Heading Level 6',
    description: 'Level 6 heading using ATX syntax',
  );

  // Heading with inline formatting
  _convertAndStore(
    headings,
    'heading_with_emphasis',
    '# Heading with **bold** and *italic*',
    description: 'Heading containing inline formatting elements',
  );

  // Heading with auto-generated ID (GitHub Web extension)
  _convertAndStore(
    headings,
    'heading_with_id',
    '# Custom Heading',
    description: 'Heading that generates an automatic ID for linking',
  );

  // Setext headings
  _convertAndStore(
    headings,
    'h1_setext',
    'Setext Level 1\n===============',
    description: 'Level 1 heading using setext syntax',
  );

  _convertAndStore(
    headings,
    'h2_setext',
    'Setext Level 2\n---------------',
    description: 'Level 2 heading using setext syntax',
  );
}

void _generateParagraphs(Map<String, dynamic> block) {
  block['paragraphs'] = <String, dynamic>{};
  final paragraphs = block['paragraphs'] as Map<String, dynamic>;

  _convertAndStore(
    paragraphs,
    'simple_paragraph',
    'This is a simple paragraph with plain text.',
    description: 'Basic paragraph element with text content',
  );

  _convertAndStore(
    paragraphs,
    'multiple_paragraphs',
    'First paragraph.\n\nSecond paragraph.\n\nThird paragraph.',
    description: 'Multiple paragraphs separated by blank lines',
  );

  _convertAndStore(
    paragraphs,
    'paragraph_with_inline',
    'Paragraph with **bold**, *italic*, and `code`.',
    description: 'Paragraph containing various inline elements',
  );
}

void _generateBlockquotes(Map<String, dynamic> block) {
  block['blockquotes'] = <String, dynamic>{};
  final blockquotes = block['blockquotes'] as Map<String, dynamic>;

  _convertAndStore(
    blockquotes,
    'simple_blockquote',
    '> This is a blockquote.',
    description: 'Simple blockquote with single line',
  );

  _convertAndStore(
    blockquotes,
    'multiline_blockquote',
    '> First line of quote.\n> Second line of quote.\n> Third line of quote.',
    description: 'Blockquote spanning multiple lines',
  );

  _convertAndStore(
    blockquotes,
    'nested_blockquote',
    '> Outer quote\n>> Nested quote\n>>> Deeply nested quote',
    description: 'Blockquotes nested within blockquotes',
  );

  _convertAndStore(
    blockquotes,
    'blockquote_with_formatting',
    '> Quote with **bold** and *italic*\n>\n> And a second paragraph.',
    description: 'Blockquote containing inline formatting and paragraphs',
  );
}

void _generateLists(Map<String, dynamic> block) {
  block['lists'] = <String, dynamic>{};
  final lists = block['lists'] as Map<String, dynamic>;

  // Unordered lists
  _convertAndStore(
    lists,
    'unordered_list_dash',
    '- Item 1\n- Item 2\n- Item 3',
    description: 'Unordered list using dash (-) markers',
  );

  _convertAndStore(
    lists,
    'unordered_list_asterisk',
    '* Item 1\n* Item 2\n* Item 3',
    description: 'Unordered list using asterisk (*) markers',
  );

  _convertAndStore(
    lists,
    'unordered_list_plus',
    '+ Item 1\n+ Item 2\n+ Item 3',
    description: 'Unordered list using plus (+) markers',
  );

  // Ordered lists
  _convertAndStore(
    lists,
    'ordered_list',
    '1. First item\n2. Second item\n3. Third item',
    description: 'Ordered list with sequential numbers',
  );

  _convertAndStore(
    lists,
    'ordered_list_start_any',
    '5. Fifth item\n6. Sixth item\n7. Seventh item',
    description: 'Ordered list starting at number 5',
  );

  // Nested lists
  _convertAndStore(
    lists,
    'nested_list',
    '- Parent item 1\n  - Child item 1.1\n  - Child item 1.2\n- Parent item 2\n  - Child item 2.1',
    description: 'Nested unordered list with parent and child items',
  );

  _convertAndStore(
    lists,
    'mixed_nested_list',
    '1. Ordered parent\n   - Unordered child\n   - Another child\n2. Second ordered',
    description: 'Mixed ordered and unordered nested lists',
  );

  // Task lists (GitHub extension)
  _convertAndStore(
    lists,
    'task_list',
    '- [ ] Unchecked task\n- [x] Checked task\n- [ ] Another unchecked task',
    description: 'Task list with checked and unchecked items',
  );

  // List with multiple paragraphs
  _convertAndStore(
    lists,
    'list_with_paragraphs',
    '- First item\n\n  Second paragraph in first item\n\n- Second item',
    description: 'List items containing multiple paragraphs',
  );

  // List with code blocks
  _convertAndStore(
    lists,
    'list_with_code',
    '- Item with code:\n\n  ```\n  code block\n  ```\n\n- Next item',
    description: 'List items containing code blocks',
  );
}

void _generateCodeBlocks(Map<String, dynamic> block) {
  block['code_blocks'] = <String, dynamic>{};
  final codeBlocks = block['code_blocks'] as Map<String, dynamic>;

  // Indented code blocks
  _convertAndStore(
    codeBlocks,
    'indented_code',
    '    code line 1\n    code line 2\n    code line 3',
    description: 'Code block using 4-space indentation',
  );

  // Fenced code blocks
  _convertAndStore(
    codeBlocks,
    'fenced_code_backtick',
    '```\ncode line 1\ncode line 2\n```',
    description: 'Fenced code block using backticks',
  );

  _convertAndStore(
    codeBlocks,
    'fenced_code_tilde',
    '~~~\ncode line 1\ncode line 2\n~~~',
    description: 'Fenced code block using tildes',
  );

  // With language identifier
  _convertAndStore(
    codeBlocks,
    'fenced_code_dart',
    '```dart\nvoid main() {\n  print("Hello");\n}\n```',
    description: 'Fenced code block with Dart language identifier',
  );

  _convertAndStore(
    codeBlocks,
    'fenced_code_javascript',
    '```javascript\nconst x = 42;\nconsole.log(x);\n```',
    description: 'Fenced code block with JavaScript language identifier',
  );

  _convertAndStore(
    codeBlocks,
    'fenced_code_json',
    '```json\n{\n  "key": "value",\n  "number": 123\n}\n```',
    description: 'Fenced code block with JSON language identifier',
  );
}

void _generateTables(Map<String, dynamic> block) {
  block['tables'] = <String, dynamic>{};
  final tables = block['tables'] as Map<String, dynamic>;

  // Simple table
  _convertAndStore(
    tables,
    'simple_table',
    '| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n| Cell 3   | Cell 4   |',
    description: 'Simple table with headers and two rows',
  );

  // Table with alignment
  _convertAndStore(
    tables,
    'table_with_alignment',
    '| Left | Center | Right |\n|:-----|:------:|------:|\n| L1   | C1     | R1    |\n| L2   | C2     | R2    |',
    description: 'Table with left, center, and right alignment',
  );

  // Table with inline formatting
  _convertAndStore(
    tables,
    'table_with_formatting',
    '| **Bold** | *Italic* | `Code` |\n|----------|----------|--------|\n| **B1**   | *I1*     | `C1`   |',
    description: 'Table cells containing inline formatting',
  );

  // Table with links and images
  _convertAndStore(
    tables,
    'table_with_links',
    '| Link | Image |\n|------|-------|\n| [text](url) | ![alt](img.png) |',
    description: 'Table cells containing links and images',
  );
}

void _generateAlerts(Map<String, dynamic> block) {
  block['alerts'] = <String, dynamic>{};
  final alerts = block['alerts'] as Map<String, dynamic>;

  _convertAndStore(
    alerts,
    'alert_note',
    '> [!NOTE]\n> This is a note alert.',
    description: 'NOTE alert block (informational)',
  );

  _convertAndStore(
    alerts,
    'alert_tip',
    '> [!TIP]\n> This is a tip alert.',
    description: 'TIP alert block (helpful advice)',
  );

  _convertAndStore(
    alerts,
    'alert_important',
    '> [!IMPORTANT]\n> This is an important alert.',
    description: 'IMPORTANT alert block (critical information)',
  );

  _convertAndStore(
    alerts,
    'alert_warning',
    '> [!WARNING]\n> This is a warning alert.',
    description: 'WARNING alert block (caution)',
  );

  _convertAndStore(
    alerts,
    'alert_caution',
    '> [!CAUTION]\n> This is a caution alert.',
    description: 'CAUTION alert block (danger)',
  );

  _convertAndStore(
    alerts,
    'alert_multiline',
    '> [!NOTE]\n> First line of alert.\n> Second line of alert.\n>\n> Paragraph in alert.',
    description: 'Multi-paragraph alert block',
  );
}

void _generateHorizontalRules(Map<String, dynamic> block) {
  block['horizontal_rules'] = <String, dynamic>{};
  final hrs = block['horizontal_rules'] as Map<String, dynamic>;

  _convertAndStore(
    hrs,
    'hr_dashes',
    '---',
    description: 'Horizontal rule using three dashes',
  );

  _convertAndStore(
    hrs,
    'hr_asterisks',
    '***',
    description: 'Horizontal rule using three asterisks',
  );

  _convertAndStore(
    hrs,
    'hr_underscores',
    '___',
    description: 'Horizontal rule using three underscores',
  );

  _convertAndStore(
    hrs,
    'hr_many_dashes',
    '----------',
    description: 'Horizontal rule using many dashes',
  );
}

// ============================================================================
// INLINE ELEMENTS
// ============================================================================

void _generateTextFormatting(Map<String, dynamic> inline) {
  inline['text_formatting'] = <String, dynamic>{};
  final formatting = inline['text_formatting'] as Map<String, dynamic>;

  // Plain text
  _convertAndStore(
    formatting,
    'plain_text',
    'Just plain text.',
    description: 'Plain text node without formatting',
  );

  // Strong (bold)
  _convertAndStore(
    formatting,
    'strong_asterisk',
    '**bold text**',
    description: 'Strong/bold using double asterisks',
  );

  _convertAndStore(
    formatting,
    'strong_underscore',
    '__bold text__',
    description: 'Strong/bold using double underscores',
  );

  // Emphasis (italic)
  _convertAndStore(
    formatting,
    'em_asterisk',
    '*italic text*',
    description: 'Emphasis/italic using single asterisks',
  );

  _convertAndStore(
    formatting,
    'em_underscore',
    '_italic text_',
    description: 'Emphasis/italic using single underscores',
  );

  // Combined strong and emphasis
  _convertAndStore(
    formatting,
    'strong_and_em',
    '***bold and italic***',
    description: 'Combined bold and italic using triple asterisks',
  );

  _convertAndStore(
    formatting,
    'nested_strong_em',
    '**bold with *italic* inside**',
    description: 'Italic nested within bold',
  );

  _convertAndStore(
    formatting,
    'nested_em_strong',
    '*italic with **bold** inside*',
    description: 'Bold nested within italic',
  );

  // Strikethrough (GitHub extension)
  _convertAndStore(
    formatting,
    'strikethrough',
    '~~strikethrough text~~',
    description: 'Strikethrough/deleted text',
  );

  // Combined formatting
  _convertAndStore(
    formatting,
    'all_formatting',
    'Text with **bold**, *italic*, ***both***, and ~~strikethrough~~.',
    description: 'Multiple formatting types in one paragraph',
  );
}

void _generateLinks(Map<String, dynamic> inline) {
  inline['links'] = <String, dynamic>{};
  final links = inline['links'] as Map<String, dynamic>;

  // Inline links
  _convertAndStore(
    links,
    'inline_link',
    '[link text](https://example.com)',
    description: 'Inline link with URL',
  );

  _convertAndStore(
    links,
    'inline_link_with_title',
    '[link text](https://example.com "Link Title")',
    description: 'Inline link with URL and title attribute',
  );

  // Reference links
  _convertAndStore(
    links,
    'reference_link',
    '[link text][ref]\n\n[ref]: https://example.com',
    description: 'Reference-style link with definition',
    includeMetadata: true,
  );

  _convertAndStore(
    links,
    'reference_link_with_title',
    '[link text][ref]\n\n[ref]: https://example.com "Title"',
    description: 'Reference link with title in definition',
    includeMetadata: true,
  );

  _convertAndStore(
    links,
    'reference_link_implicit',
    '[Example]\n\n[example]: https://example.com',
    description: 'Implicit reference link (text is reference)',
    includeMetadata: true,
  );

  // Autolinks
  _convertAndStore(
    links,
    'autolink',
    '<https://example.com>',
    description: 'Autolink using angle brackets',
  );

  _convertAndStore(
    links,
    'autolink_email',
    '<user@example.com>',
    description: 'Email autolink',
  );

  // Link with formatting
  _convertAndStore(
    links,
    'link_with_emphasis',
    '[**bold link**](https://example.com)',
    description: 'Link text containing bold formatting',
  );

  // Naked URL (GitHub extension)
  _convertAndStore(
    links,
    'naked_url',
    'Visit https://example.com for more.',
    description: 'Bare URL automatically converted to link',
  );

  _convertAndStore(
    links,
    'autolink_trailing_punctuation',
    'Visit <https://example.com>. Or see https://example.org.',
    description:
        'Autolinks with trailing punctuation handled by the autolink extension',
  );
}

void _generateImages(Map<String, dynamic> inline) {
  inline['images'] = <String, dynamic>{};
  final images = inline['images'] as Map<String, dynamic>;

  // Inline images
  _convertAndStore(
    images,
    'inline_image',
    '![alt text](image.png)',
    description: 'Inline image with alt text',
  );

  _convertAndStore(
    images,
    'inline_image_with_title',
    '![alt text](image.png "Image Title")',
    description: 'Inline image with alt text and title',
  );

  // Reference images
  _convertAndStore(
    images,
    'reference_image',
    '![alt text][img]\n\n[img]: image.png',
    description: 'Reference-style image',
    includeMetadata: true,
  );

  _convertAndStore(
    images,
    'reference_image_with_title',
    '![alt text][img]\n\n[img]: image.png "Title"',
    description: 'Reference image with title',
    includeMetadata: true,
  );

  // Image as link
  _convertAndStore(
    images,
    'linked_image',
    '[![alt text](image.png)](https://example.com)',
    description: 'Image wrapped in a link (clickable image)',
  );
}

void _generateInlineCode(Map<String, dynamic> inline) {
  inline['inline_code'] = <String, dynamic>{};
  final code = inline['inline_code'] as Map<String, dynamic>;

  _convertAndStore(
    code,
    'simple_code',
    'Text with `code` inline.',
    description: 'Inline code span using backticks',
  );

  _convertAndStore(
    code,
    'code_with_backtick',
    'Code with `` ` `` backtick inside.',
    description: 'Inline code containing a backtick character',
  );

  _convertAndStore(
    code,
    'code_multiple',
    'Multiple `code1` and `code2` spans.',
    description: 'Multiple inline code spans in one paragraph',
  );
}

void _generateLineBreaks(Map<String, dynamic> inline) {
  inline['line_breaks'] = <String, dynamic>{};
  final breaks = inline['line_breaks'] as Map<String, dynamic>;

  _convertAndStore(
    breaks,
    'hard_break_spaces',
    'Line 1  \nLine 2',
    description: 'Hard line break using two trailing spaces',
  );

  _convertAndStore(
    breaks,
    'hard_break_backslash',
    'Line 1\\\nLine 2',
    description: 'Hard line break using backslash',
  );

  _convertAndStore(
    breaks,
    'soft_break',
    'Line 1\nLine 2',
    description: 'Soft line break (becomes space in output)',
  );
}

void _generateColorSwatches(Map<String, dynamic> inline) {
  inline['color_swatches'] = <String, dynamic>{};
  final swatches = inline['color_swatches'] as Map<String, dynamic>;

  _convertAndStore(
    swatches,
    'hex_color_swatch',
    '`#FF0000`',
    description: 'Inline color swatch with hex value',
  );

  _convertAndStore(
    swatches,
    'rgb_color_swatch',
    '`rgb(0, 128, 255)`',
    description: 'Inline color swatch with rgb() function',
  );
}

void _generateEmoji(Map<String, dynamic> inline) {
  inline['emoji'] = <String, dynamic>{};
  final emoji = inline['emoji'] as Map<String, dynamic>;

  _convertAndStore(
    emoji,
    'emoji_inline',
    'I :heart: Dart',
    description: 'Emoji shortcode converted by the emoji syntax',
  );
}

void _generateInlineHtml(Map<String, dynamic> inline) {
  inline['inline_html'] = <String, dynamic>{};
  final html = inline['inline_html'] as Map<String, dynamic>;

  _convertAndStore(
    html,
    'inline_html_span',
    'Hello <span class="highlight">world</span>!',
    description: 'Inline HTML preserved by the inline HTML syntax',
  );
}

// ============================================================================
// SPECIAL CASES
// ============================================================================

void _generateEmptyElements(Map<String, dynamic> special) {
  special['empty_elements'] = <String, dynamic>{};
  final empty = special['empty_elements'] as Map<String, dynamic>;

  _convertAndStore(
    empty,
    'horizontal_rule',
    '---',
    description: 'Self-closing hr element',
  );

  _convertAndStore(
    empty,
    'line_break',
    'Text  \nwith break',
    description: 'Self-closing br element',
  );

  _convertAndStore(
    empty,
    'image',
    '![alt](img.png)',
    description: 'Self-closing img element',
  );
}

void _generateElementsWithAttributes(Map<String, dynamic> special) {
  special['elements_with_attributes'] = <String, dynamic>{};
  final attrs = special['elements_with_attributes'] as Map<String, dynamic>;

  _convertAndStore(
    attrs,
    'link_attributes',
    '[text](https://example.com "Title")',
    description: 'Link with href and title attributes',
  );

  _convertAndStore(
    attrs,
    'image_attributes',
    '![alt text](image.png "Image title")',
    description: 'Image with src, alt, and title attributes',
  );

  _convertAndStore(
    attrs,
    'heading_with_id',
    '# Heading Text',
    description: 'Heading with auto-generated ID attribute',
  );

  _convertAndStore(
    attrs,
    'table_alignment',
    '| Left | Center | Right |\n|:-----|:------:|------:|\n| L    | C      | R     |',
    description: 'Table cells with alignment attributes',
  );

  _convertAndStore(
    attrs,
    'task_list_checkbox',
    '- [x] Task',
    description: 'List item with checkbox input attributes',
  );
}

void _generateEscapedCharacters(Map<String, dynamic> special) {
  special['escaped_characters'] = <String, dynamic>{};
  final escaped = special['escaped_characters'] as Map<String, dynamic>;

  _convertAndStore(
    escaped,
    'escaped_asterisk',
    r'Text with \* escaped asterisk.',
    description: 'Escaped asterisk (not emphasis)',
  );

  _convertAndStore(
    escaped,
    'escaped_underscore',
    r'Text with \_ escaped underscore.',
    description: 'Escaped underscore (not emphasis)',
  );

  _convertAndStore(
    escaped,
    'escaped_backtick',
    r'Text with \` escaped backtick.',
    description: 'Escaped backtick (not code)',
  );

  _convertAndStore(
    escaped,
    'escaped_brackets',
    r'Text with \[brackets\] escaped.',
    description: 'Escaped square brackets (not link)',
  );

  _convertAndStore(
    escaped,
    'html_entities',
    'Text with &amp; &lt; &gt; entities.',
    description: 'HTML entities in text',
  );
}

// ============================================================================
// COMPLEX NESTED STRUCTURES
// ============================================================================

void _generateNestedStructures(Map<String, dynamic> complex) {
  complex['nested_structures'] = <String, dynamic>{};
  final nested = complex['nested_structures'] as Map<String, dynamic>;

  _convertAndStore(
    nested,
    'list_in_blockquote',
    '> - Item 1\n> - Item 2\n> - Item 3',
    description: 'Unordered list nested within blockquote',
  );

  _convertAndStore(
    nested,
    'blockquote_in_list',
    '- Item 1\n\n  > Quote in list\n\n- Item 2',
    description: 'Blockquote nested within list item',
  );

  _convertAndStore(
    nested,
    'code_in_list',
    '- Item with code:\n\n  ```\n  code here\n  ```',
    description: 'Code block nested within list item',
  );

  _convertAndStore(
    nested,
    'table_in_list',
    '- Item\n\n  | Col 1 | Col 2 |\n  |-------|-------|\n  | A     | B     |',
    description: 'Table nested within list item',
  );

  _convertAndStore(
    nested,
    'deeply_nested_lists',
    '- Level 1\n  - Level 2\n    - Level 3\n      - Level 4',
    description: 'Four levels of nested lists',
  );

  _convertAndStore(
    nested,
    'mixed_formatting',
    '**Bold with *italic* and `code` inside**',
    description: 'Multiple inline elements nested',
  );

  _convertAndStore(
    nested,
    'link_with_emphasis',
    '[**Bold link** with *italic*](https://example.com)',
    description: 'Link containing bold and italic text',
  );

  _convertAndStore(
    nested,
    'complex_paragraph',
    'Paragraph with **bold**, *italic*, `code`, [link](url), ![image](img.png), and ~~strikethrough~~.',
    description: 'Paragraph with all inline element types',
  );
}

void _generateFootnotes(Map<String, dynamic> complex) {
  complex['footnotes'] = <String, dynamic>{};
  final footnotes = complex['footnotes'] as Map<String, dynamic>;

  _convertAndStore(
    footnotes,
    'simple_footnote',
    'Text with footnote[^1].\n\n[^1]: Footnote content.',
    description: 'Simple footnote reference and definition',
    includeMetadata: true,
  );

  _convertAndStore(
    footnotes,
    'multiple_footnotes',
    'First[^1] and second[^2].\n\n[^1]: First note.\n[^2]: Second note.',
    description: 'Multiple footnote references',
    includeMetadata: true,
  );

  _convertAndStore(
    footnotes,
    'footnote_multiline',
    'Text[^note].\n\n[^note]: First paragraph.\n\n    Second paragraph.',
    description: 'Footnote with multiple paragraphs',
    includeMetadata: true,
  );
}

// ============================================================================
// METADATA EXAMPLES
// ============================================================================

void _generateMetadataExamples(Map<String, dynamic> metadata) {
  _convertAndStore(
    metadata,
    'link_references',
    'See [example] and [test].\n\n[example]: https://example.com "Example"\n[test]: https://test.com',
    description: 'Document with multiple link reference definitions',
    includeMetadata: true,
  );

  _convertAndStore(
    metadata,
    'footnote_tracking',
    'First[^1], second[^2], first again[^1].\n\n[^1]: Note 1.\n[^2]: Note 2.',
    description: 'Footnote reference counting and label ordering',
    includeMetadata: true,
  );

  _convertAndStore(
    metadata,
    'comprehensive_metadata',
    '# Heading\n\nText with [link][ref] and footnote[^note].\n\n[ref]: https://example.com\n[^note]: Footnote.',
    description: 'Document with all metadata types',
    includeMetadata: true,
  );
}
