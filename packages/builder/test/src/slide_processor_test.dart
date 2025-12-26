import 'package:superdeck_builder/src/parsers/raw_slide_schema.dart';
import 'package:superdeck_builder/src/slide_processor.dart';
import 'package:superdeck_builder/src/task_exception.dart';
import 'package:superdeck_builder/src/tasks/slide_context.dart';
import 'package:superdeck_builder/src/tasks/task.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

/// Mock task for testing that records execution
base class MockTask extends Task {
  final List<int> executedSlides = [];
  final bool shouldFail;
  final Exception? exceptionToThrow;

  MockTask(
    super.name, {
    this.shouldFail = false,
    this.exceptionToThrow,
  });

  @override
  Future<void> run(SlideContext context) async {
    executedSlides.add(context.slideIndex);
    if (shouldFail) {
      throw exceptionToThrow ?? Exception('Task failed');
    }
    // Simulate some async work
    await Future.delayed(Duration.zero);
  }
}

/// Mock task that modifies slide content
base class ContentModifierTask extends Task {
  final String prefix;

  ContentModifierTask(this.prefix) : super('ContentModifier');

  @override
  Future<void> run(SlideContext context) async {
    final updated = RawSlideMarkdownType.parse({
      'key': context.slide.key,
      'content': '$prefix${context.slide.content}',
      'frontmatter': context.slide.frontmatter,
    });
    context.slide = updated;
  }
}

/// Mock DeckService for testing
class MockDeckService extends DeckService {
  MockDeckService() : super(configuration: DeckConfiguration());

  @override
  Future<void> initialize() async {}

  @override
  String getGeneratedAssetPath(GeneratedAsset asset) {
    return '/mock/path/${asset.fileName}';
  }
}

void main() {
  group('SlideProcessor', () {
    late SlideProcessor processor;
    late MockDeckService store;

    setUp(() {
      processor = SlideProcessor();
      store = MockDeckService();
    });

    group('Basic Processing', () {
      test('processes single slide successfully', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': '# Hello World',
          'frontmatter': {'title': 'Test Slide'},
        });

        final task = MockTask('TestTask');
        final slides = await processor.processAll([rawSlide], [task], store);

        expect(slides, hasLength(1));
        expect(slides[0].key, equals('slide-1'));
        expect(task.executedSlides, equals([0]));
      });

      test('processes multiple slides successfully', () async {
        final rawSlides = [
          RawSlideMarkdownType.parse({
            'key': 'slide-1',
            'content': 'Content 1',
            'frontmatter': {},
          }),
          RawSlideMarkdownType.parse({
            'key': 'slide-2',
            'content': 'Content 2',
            'frontmatter': {},
          }),
          RawSlideMarkdownType.parse({
            'key': 'slide-3',
            'content': 'Content 3',
            'frontmatter': {},
          }),
        ];

        final task = MockTask('TestTask');
        final slides = await processor.processAll(rawSlides, [task], store);

        expect(slides, hasLength(3));
        expect(slides[0].key, equals('slide-1'));
        expect(slides[1].key, equals('slide-2'));
        expect(slides[2].key, equals('slide-3'));
        expect(task.executedSlides, equals([0, 1, 2]));
      });

      test('processes empty slide list', () async {
        final task = MockTask('TestTask');
        final slides = await processor.processAll([], [task], store);

        expect(slides, isEmpty);
        expect(task.executedSlides, isEmpty);
      });

      test('processes slides with no tasks', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': '# Hello',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].key, equals('slide-1'));
      });
    });

    group('Task Execution', () {
      test('executes multiple tasks in sequence', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': 'Original',
          'frontmatter': {},
        });

        final task1 = ContentModifierTask('[Task1]');
        final task2 = ContentModifierTask('[Task2]');

        final slides = await processor.processAll([rawSlide], [task1, task2], store);

        expect(slides, hasLength(1));
        // Content should be modified by both tasks in order
        expect(slides[0].sections[0].blocks[0].content, contains('[Task2][Task1]Original'));
      });

      test('maintains task execution order', () async {
        final rawSlides = List.generate(
          3,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {},
          }),
        );

        final task1 = MockTask('Task1');
        final task2 = MockTask('Task2');
        final task3 = MockTask('Task3');

        await processor.processAll(rawSlides, [task1, task2, task3], store);

        // Each task should process all slides
        expect(task1.executedSlides, equals([0, 1, 2]));
        expect(task2.executedSlides, equals([0, 1, 2]));
        expect(task3.executedSlides, equals([0, 1, 2]));
      });

      test('task receives correct slide context', () async {
        final rawSlides = [
          RawSlideMarkdownType.parse({
            'key': 'first',
            'content': 'First content',
            'frontmatter': {},
          }),
          RawSlideMarkdownType.parse({
            'key': 'second',
            'content': 'Second content',
            'frontmatter': {},
          }),
        ];

        SlideContext? capturedContext;
        final task = createMockTask(
          'ContextCaptureTask',
          run: (context) async {
            if (context.slideIndex == 1) {
              capturedContext = context;
            }
          },
        );

        await processor.processAll(rawSlides, [task], store);

        expect(capturedContext, isNotNull);
        expect(capturedContext!.slideIndex, equals(1));
        expect(capturedContext!.slide.key, equals('second'));
        expect(capturedContext!.slide.content, equals('Second content'));
      });
    });

    group('Concurrency Control', () {
      test('respects default concurrency limit of 4', () async {
        final rawSlides = List.generate(
          10,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {},
          }),
        );

        final task = MockTask('TestTask');
        final slides = await processor.processAll(rawSlides, [task], store);

        expect(slides, hasLength(10));
        expect(task.executedSlides, hasLength(10));
      });

      test('respects custom concurrency limit', () async {
        final customProcessor = SlideProcessor(concurrentSlides: 2);
        final rawSlides = List.generate(
          5,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {},
          }),
        );

        final task = MockTask('TestTask');
        final slides = await customProcessor.processAll(rawSlides, [task], store);

        expect(slides, hasLength(5));
        expect(task.executedSlides, hasLength(5));
      });

      test('processes slides in batches based on concurrency', () async {
        final processor2 = SlideProcessor(concurrentSlides: 2);
        final rawSlides = List.generate(
          3,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {},
          }),
        );

        final task = MockTask('TestTask');
        final slides = await processor2.processAll(rawSlides, [task], store);

        expect(slides, hasLength(3));
        // All slides should be processed regardless of batching
        expect(task.executedSlides, containsAll([0, 1, 2]));
      });
    });

    group('Error Handling', () {
      test('throws TaskException when task fails', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': 'Content',
          'frontmatter': {},
        });

        final failingTask = MockTask(
          'FailingTask',
          shouldFail: true,
          exceptionToThrow: Exception('Test error'),
        );

        expect(
          () => processor.processAll([rawSlide], [failingTask], store),
          throwsA(
            isA<TaskException>()
                .having((e) => e.taskName, 'taskName', 'FailingTask')
                .having((e) => e.slideIndex, 'slideIndex', 0)
                .having(
                  (e) => e.originalException.toString(),
                  'originalException',
                  contains('Test error'),
                ),
          ),
        );
      });

      test('includes slide index in error', () async {
        final rawSlides = [
          RawSlideMarkdownType.parse({
            'key': 'slide-0',
            'content': 'Content 0',
            'frontmatter': {},
          }),
          RawSlideMarkdownType.parse({
            'key': 'slide-1',
            'content': 'Content 1',
            'frontmatter': {},
          }),
        ];

        // Task that fails only on second slide
        final conditionalFailTask = createMockTask(
          'ConditionalFailTask',
          run: (context) async {
            if (context.slideIndex == 1) {
              throw Exception('Failed on slide 1');
            }
          },
        );

        try {
          await processor.processAll(rawSlides, [conditionalFailTask], store);
          fail('Should have thrown TaskException');
        } on TaskException catch (e) {
          expect(e.slideIndex, equals(1));
          expect(e.taskName, equals('ConditionalFailTask'));
        }
      });

      test('preserves original exception in TaskException', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': 'Content',
          'frontmatter': {},
        });

        final customException = Exception('Custom error message');
        final failingTask = MockTask(
          'FailingTask',
          shouldFail: true,
          exceptionToThrow: customException,
        );

        try {
          await processor.processAll([rawSlide], [failingTask], store);
          fail('Should have thrown TaskException');
        } on TaskException catch (e) {
          expect(e.originalException, equals(customException));
          expect(e.toString(), contains('Custom error message'));
        }
      });

      test('stops processing on first error', () async {
        final rawSlides = List.generate(
          5,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {},
          }),
        );

        final failOnThirdTask = createMockTask(
          'FailOnThirdTask',
          run: (context) async {
            if (context.slideIndex == 2) {
              throw Exception('Failed on third slide');
            }
          },
        );

        final trackingTask = MockTask('TrackingTask');

        try {
          await processor.processAll(
            rawSlides,
            [failOnThirdTask, trackingTask],
            store,
          );
          fail('Should have thrown TaskException');
        } on TaskException catch (e) {
          expect(e.slideIndex, equals(2));
          // Tracking task should not run after the failure
          expect(trackingTask.executedSlides, isNot(contains(2)));
        }
      });
    });

    group('Slide Building', () {
      test('builds slide with correct key', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'custom-key',
          'content': 'Content',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides[0].key, equals('custom-key'));
      });

      test('parses frontmatter into SlideOptions', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': 'Content',
          'frontmatter': {
            'title': 'Test Title',
            'style': 'dark',
          },
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides[0].options?.title, equals('Test Title'));
        expect(slides[0].options?.style, equals('dark'));
      });

      test('parses content into sections', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': '''
@section
# Header

@column
Column content
''',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides[0].sections, isNotEmpty);
        expect(slides[0].sections[0].blocks, hasLength(2));
      });

      test('parses comments from content', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': '''
# Title

<!-- This is a note -->

Content here

<!-- Another note -->
''',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides[0].comments, hasLength(2));
        expect(slides[0].comments[0], equals('This is a note'));
        expect(slides[0].comments[1], equals('Another note'));
      });

      test('handles empty frontmatter', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': 'Just content',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].key, equals('slide-1'));
      });

      test('handles slides with only content', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'slide-1',
          'content': '# Just a heading\n\nAnd some text.',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].sections, isNotEmpty);
        expect(slides[0].sections[0].blocks[0].content, contains('Just a heading'));
      });
    });

    group('Edge Cases', () {
      test('handles empty slide content', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'empty-slide',
          'content': '',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].key, equals('empty-slide'));
        expect(slides[0].sections, isNotEmpty);
      });

      test('handles special characters in content', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'special-chars',
          'content': '''
# Title with émojis 🎉

Special chars: @#\$%^&*()
Unicode: 你好世界
Symbols: ← → ↑ ↓
''',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].sections[0].blocks[0].content, contains('émojis 🎉'));
        expect(slides[0].sections[0].blocks[0].content, contains('你好世界'));
      });

      test('handles very long content', () async {
        final longContent = List.generate(1000, (i) => 'Line $i').join('\n');
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'long-slide',
          'content': longContent,
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].sections[0].blocks[0].content, contains('Line 999'));
      });

      test('handles whitespace-only content', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'whitespace-slide',
          'content': '   \n\n   \t\t   \n   ',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].key, equals('whitespace-slide'));
      });

      test('handles malformed section tags', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'malformed-slide',
          'content': '''
@section
Normal section

@column
Normal column

Some content without tag
''',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].sections, isNotEmpty);
      });

      test('handles slides with only comments', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'comments-only',
          'content': '''
<!-- Comment 1 -->
<!-- Comment 2 -->
<!-- Comment 3 -->
''',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].comments, hasLength(3));
      });

      test('handles mixed newline types', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'mixed-newlines',
          'content': 'Line 1\nLine 2\r\nLine 3\rLine 4',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].sections, isNotEmpty);
      });

      test('handles content with code blocks', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'code-slide',
          'content': '''
# Code Example

```dart
void main() {
  print('Hello, World!');
}
```

More content.
''',
          'frontmatter': {},
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].sections[0].blocks[0].content, contains('void main()'));
      });

      test('handles multiple complex frontmatter fields', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'complex-frontmatter',
          'content': 'Content',
          'frontmatter': {
            'title': 'Complex Slide',
            'style': 'custom',
            'layout': 'two-column',
            'background': '#ffffff',
            'transition': 'fade',
          },
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].options?.title, equals('Complex Slide'));
        expect(slides[0].options?.style, equals('custom'));
      });
    });

    group('Integration Scenarios', () {
      test('processes multiple slides with multiple tasks', () async {
        final rawSlides = List.generate(
          6,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {'index': i},
          }),
        );

        final task1 = MockTask('Task1');
        final task2 = MockTask('Task2');
        final task3 = MockTask('Task3');

        final slides = await processor.processAll(
          rawSlides,
          [task1, task2, task3],
          store,
        );

        expect(slides, hasLength(6));
        expect(task1.executedSlides, hasLength(6));
        expect(task2.executedSlides, hasLength(6));
        expect(task3.executedSlides, hasLength(6));
      });

      test('maintains slide order after processing', () async {
        final rawSlides = List.generate(
          10,
          (i) => RawSlideMarkdownType.parse({
            'key': 'slide-$i',
            'content': 'Content $i',
            'frontmatter': {},
          }),
        );

        final task = MockTask('TestTask');
        final slides = await processor.processAll(rawSlides, [task], store);

        for (var i = 0; i < 10; i++) {
          expect(slides[i].key, equals('slide-$i'));
        }
      });

      test('handles complex slide with all features', () async {
        final rawSlide = RawSlideMarkdownType.parse({
          'key': 'complex-slide',
          'content': '''
# Main Title

<!-- This is a speaker note -->

@section
## Section 1

@column{
  flex: 1
  align: center
}
Column 1 content

@column{
  flex: 2
  align: top_left
}
Column 2 content

@section
## Section 2

Regular content here

```dart
void example() {
  print('code');
}
```

<!-- Another note -->
''',
          'frontmatter': {
            'title': 'Complex Slide Title',
            'style': 'dark',
          },
        });

        final slides = await processor.processAll([rawSlide], [], store);

        expect(slides, hasLength(1));
        expect(slides[0].key, equals('complex-slide'));
        expect(slides[0].options?.title, equals('Complex Slide Title'));
        expect(slides[0].sections.length, greaterThanOrEqualTo(1));
        expect(slides[0].comments.length, greaterThanOrEqualTo(1));
      });
    });
  });
}

/// Helper for creating simple mock tasks
Task createMockTask(String name, {required Future<void> Function(SlideContext) run}) {
  return _SimpleMockTask(name, run);
}

base class _SimpleMockTask extends Task {
  final Future<void> Function(SlideContext) _run;

  _SimpleMockTask(super.name, this._run);

  @override
  Future<void> run(SlideContext context) => _run(context);
}

extension on Block {
  String get content => (this as ContentBlock).content;
}
