import 'package:superdeck/superdeck.dart';

/// Purpose-built slide fixtures for widget/behavior tests.
///
/// All keys are deterministic (no timestamps) to keep tests stable.
class SlideFixtures {
  // ---------- Basic layouts ----------

  /// Single column, single section, center aligned.
  static Slide singleColumn({String content = '# Hello World'}) {
    return _slide(
      'fixture-single-column',
      [
        SectionBlock([
          ContentBlock(
            content,
            align: ContentAlignment.center,
          ),
        ]),
      ],
    );
  }

  /// Two columns with equal flex (1:1).
  static Slide twoColumnEqual({String? left, String? right}) {
    return _slide(
      'fixture-two-column-equal',
      [
        SectionBlock([
          ContentBlock(left ?? '# Left'),
          ContentBlock(right ?? '# Right'),
        ]),
      ],
    );
  }

  /// Two columns with unequal flex (1:2).
  static Slide twoColumnWeighted({
    int leftFlex = 1,
    int rightFlex = 2,
    String? left,
    String? right,
  }) {
    return _slide(
      'fixture-two-column-weighted',
      [
        SectionBlock([
          ContentBlock(left ?? '# Left', flex: leftFlex),
          ContentBlock(right ?? '# Right', flex: rightFlex),
        ]),
      ],
    );
  }

  /// Three columns (1:1:1) for symmetric layouts.
  static Slide threeColumn() {
    return _slide(
      'fixture-three-column',
      [
        SectionBlock([
          ContentBlock('# One'),
          ContentBlock('# Two'),
          ContentBlock('# Three'),
        ]),
      ],
    );
  }

  /// Three columns with custom flex (defaults 1:2:1) to test weighted widths.
  static Slide threeColumnWeighted({
    int flex1 = 1,
    int flex2 = 2,
    int flex3 = 1,
  }) {
    return _slide(
      'fixture-three-column-weighted',
      [
        SectionBlock([
          ContentBlock('# One', flex: flex1),
          ContentBlock('# Two', flex: flex2),
          ContentBlock('# Three', flex: flex3),
        ]),
      ],
    );
  }

  // ---------- Multi-section layouts ----------

  /// Two stacked sections with equal flex (1:1).
  static Slide twoSectionEqual() {
    return _slide(
      'fixture-two-section-equal',
      [
        SectionBlock([ContentBlock('# Top')], flex: 1),
        SectionBlock([ContentBlock('# Bottom')], flex: 1),
      ],
    );
  }

  /// Two stacked sections with unequal flex (1:2).
  static Slide twoSectionWeighted({int topFlex = 1, int bottomFlex = 2}) {
    return _slide(
      'fixture-two-section-weighted',
      [
        SectionBlock([ContentBlock('# Top')], flex: topFlex),
        SectionBlock([ContentBlock('# Bottom')], flex: bottomFlex),
      ],
    );
  }

  /// Three stacked sections (header/body/footer pattern).
  static Slide threeSectionLayout({
    int headerFlex = 1,
    int bodyFlex = 3,
    int footerFlex = 1,
  }) {
    return _slide(
      'fixture-three-section',
      [
        SectionBlock([ContentBlock('Header')], flex: headerFlex),
        SectionBlock([ContentBlock('Body')], flex: bodyFlex),
        SectionBlock([ContentBlock('Footer')], flex: footerFlex),
      ],
    );
  }

  /// Complex: two sections; first has two columns, second has one column.
  static Slide multiSectionMultiColumn() {
    return _slide(
      'fixture-multi-section-multi-column',
      [
        SectionBlock([
          ContentBlock('Top Left'),
          ContentBlock('Top Right'),
        ], flex: 1),
        SectionBlock([
          ContentBlock('Bottom Single'),
        ], flex: 1),
      ],
    );
  }

  // ---------- Alignment variations ----------

  /// Single block with a specific alignment.
  static Slide withAlignment(ContentAlignment align) {
    return _slide(
      'fixture-with-alignment-${align.name}',
      [
        SectionBlock([
          ContentBlock(
            '# Aligned ${align.name}',
            align: align,
          ),
        ]),
      ],
    );
  }

  /// 3x3 grid showing all 9 alignment points.
  static Slide allAlignments() {
    final rows = [
      [ContentAlignment.topLeft, ContentAlignment.topCenter, ContentAlignment.topRight],
      [ContentAlignment.centerLeft, ContentAlignment.center, ContentAlignment.centerRight],
      [ContentAlignment.bottomLeft, ContentAlignment.bottomCenter, ContentAlignment.bottomRight],
    ];

    return _slide(
      'fixture-all-alignments',
      rows
          .map(
            (row) => SectionBlock(
              row
                  .map(
                    (align) => ContentBlock(
                      align.name,
                      align: align,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  // ---------- Special content ----------

  /// Scrollable block with long content to exercise SingleChildScrollView path.
  static Slide scrollableBlock({int lineCount = 50}) {
    final content = List.filled(lineCount, 'Scrollable line').join('\n');
    return _slide(
      'fixture-scrollable-block',
      [
        SectionBlock([
          ContentBlock(
            content,
            scrollable: true,
          ),
        ]),
      ],
    );
  }

  /// Non-scrollable block that should clip overflow (no scroll view).
  static Slide nonScrollableBlock({int lineCount = 50}) {
    final content = List.filled(lineCount, 'Non-scrollable line').join('\n');
    return _slide(
      'fixture-non-scrollable-block',
      [
        SectionBlock([
          ContentBlock(
            content,
            scrollable: false,
          ),
        ]),
      ],
    );
  }

  /// Block that renders a custom widget via WidgetBlock.
  static Slide withCustomWidget({
    required String widgetName,
    Map<String, dynamic> args = const {},
  }) {
    return _slide(
      'fixture-custom-widget-$widgetName',
      [
        SectionBlock([
          WidgetBlock(
            name: widgetName,
            args: args,
          ),
        ]),
      ],
    );
  }

  /// Block containing fenced code block.
  static Slide withCodeBlock({String language = 'dart'}) {
    return _slide(
      'fixture-code-block',
      [
        SectionBlock([
          ContentBlock(
            '''
```$language
void main() {
  print('hello');
}
```
''',
          ),
        ]),
      ],
    );
  }

  /// Block with mixed markdown elements (headings, lists, code, image).
  static Slide mixedMarkdown() {
    return _slide(
      'fixture-mixed-markdown',
      [
        SectionBlock([
          ContentBlock(
            '''
# Title

- Item 1
- Item 2

1. First
2. Second

`inline code`

![img](assets/test.png)
''',
          ),
        ]),
      ],
    );
  }

  // ---------- Helpers ----------

  static Slide _slide(String key, List<SectionBlock> sections) {
    return Slide(
      key: key,
      sections: sections,
    );
  }
}
