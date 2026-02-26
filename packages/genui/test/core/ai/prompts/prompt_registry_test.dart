import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_genui/src/ai/prompts/prompt_registry.dart';

void main() {
  setUp(() {
    // Reset before each test
    PromptRegistry.instance.reset();
  });

  tearDown(() {
    // Clean up after each test
    PromptRegistry.instance.reset();
  });

  group('PromptRegistry', () {
    group('initial state', () {
      test('isLoaded should be false initially', () {
        expect(PromptRegistry.instance.isLoaded, isFalse);
      });
    });

    group('render', () {
      test('throws StateError when not loaded', () {
        expect(
          () => PromptRegistry.instance.render('test'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'PromptRegistry not loaded.',
            ),
          ),
        );
      });

      test('throws StateError for missing prompt', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'existing': 'Hello {{name}}'},
        );

        expect(
          () => PromptRegistry.instance.render('nonexistent'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Prompt not found: nonexistent',
            ),
          ),
        );
      });

      test('throws StateError for empty prompt content', () {
        PromptRegistry.instance.loadForTest(prompts: {'empty': ''});

        expect(
          () => PromptRegistry.instance.render('empty'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Prompt not found: empty',
            ),
          ),
        );
      });

      test('throws StateError for whitespace-only prompt content', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'whitespace': '   \n\t  '},
        );

        expect(
          () => PromptRegistry.instance.render('whitespace'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Prompt not found: whitespace',
            ),
          ),
        );
      });

      test('returns rendered content with no variables', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'simple': 'Hello, world!'},
        );

        final result = PromptRegistry.instance.render('simple');

        expect(result, 'Hello, world!');
      });

      test('substitutes input variables', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'greeting': 'Hello, {{name}}!'},
        );

        final result = PromptRegistry.instance.render(
          'greeting',
          input: {'name': 'Alice'},
        );

        expect(result, 'Hello, Alice!');
      });

      test('substitutes multiple input variables', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'message': '{{greeting}}, {{name}}! Welcome to {{place}}.'},
        );

        final result = PromptRegistry.instance.render(
          'message',
          input: {'greeting': 'Hi', 'name': 'Bob', 'place': 'Wonderland'},
        );

        expect(result, 'Hi, Bob! Welcome to Wonderland.');
      });

      test('resolves partials', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'main': 'Header: {{>header}}'},
          partials: {'header': 'This is the header'},
        );

        final result = PromptRegistry.instance.render('main');

        expect(result, 'Header: This is the header');
      });

      test('resolves partials with variables', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'main': '{{>greeting}}'},
          partials: {'greeting': 'Hello, {{name}}!'},
        );

        final result = PromptRegistry.instance.render(
          'main',
          input: {'name': 'Charlie'},
        );

        expect(result, 'Hello, Charlie!');
      });

      test('handles missing partial gracefully', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'main': 'Before {{>missing}} After'},
          partials: {},
        );

        // Behavior depends on dotprompt_dart - likely returns empty string
        final result = PromptRegistry.instance.render('main');

        // The missing partial should be replaced with empty string
        expect(result, contains('Before'));
        expect(result, contains('After'));
      });
    });

    group('loadForTest', () {
      test('sets isLoaded to true', () {
        PromptRegistry.instance.loadForTest();

        expect(PromptRegistry.instance.isLoaded, isTrue);
      });

      test('loads prompts from provided map', () {
        PromptRegistry.instance.loadForTest(prompts: {'test': 'Test content'});

        final result = PromptRegistry.instance.render('test');

        expect(result, 'Test content');
      });

      test('loads partials from provided map', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'main': '{{>partial}}'},
          partials: {'partial': 'Partial content'},
        );

        final result = PromptRegistry.instance.render('main');

        expect(result, 'Partial content');
      });

      test('clears previous prompts', () {
        PromptRegistry.instance.loadForTest(prompts: {'first': 'First'});

        PromptRegistry.instance.loadForTest(prompts: {'second': 'Second'});

        // First prompt should no longer exist
        expect(
          () => PromptRegistry.instance.render('first'),
          throwsA(isA<StateError>()),
        );

        // Second prompt should exist
        expect(PromptRegistry.instance.render('second'), 'Second');
      });
    });

    group('reset', () {
      test('sets isLoaded to false', () {
        PromptRegistry.instance.loadForTest(prompts: {'test': 'content'});
        expect(PromptRegistry.instance.isLoaded, isTrue);

        PromptRegistry.instance.reset();

        expect(PromptRegistry.instance.isLoaded, isFalse);
      });

      test('clears prompts', () {
        PromptRegistry.instance.loadForTest(prompts: {'test': 'content'});

        PromptRegistry.instance.reset();

        // Should throw StateError because not loaded
        expect(
          () => PromptRegistry.instance.render('test'),
          throwsA(isA<StateError>()),
        );
      });

      test('can be called multiple times', () {
        expect(() {
          PromptRegistry.instance.reset();
          PromptRegistry.instance.reset();
          PromptRegistry.instance.reset();
        }, returnsNormally);
      });
    });

    group('singleton', () {
      test('instance returns same object', () {
        final instance1 = PromptRegistry.instance;
        final instance2 = PromptRegistry.instance;

        expect(identical(instance1, instance2), isTrue);
      });

      test('state persists across instance access', () {
        PromptRegistry.instance.loadForTest(prompts: {'test': 'content'});

        // Access through instance again
        final result = PromptRegistry.instance.render('test');

        expect(result, 'content');
      });
    });

    group('complex templates', () {
      test('handles multiline templates', () {
        PromptRegistry.instance.loadForTest(
          prompts: {
            'multiline': '''Line 1
Line 2
Line 3''',
          },
        );

        final result = PromptRegistry.instance.render('multiline');

        expect(result, contains('Line 1'));
        expect(result, contains('Line 2'));
        expect(result, contains('Line 3'));
      });

      test('handles special characters in content', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'special': r'Hello $name! Price: $100'},
        );

        final result = PromptRegistry.instance.render('special');

        // Dollar signs are preserved (not treated as variables)
        expect(result, contains(r'$name'));
        expect(result, contains(r'$100'));
      });

      test('handles nested partials', () {
        PromptRegistry.instance.loadForTest(
          prompts: {'main': 'Start {{>level1}} End'},
          partials: {'level1': 'L1 {{>level2}} L1', 'level2': 'L2'},
        );

        final result = PromptRegistry.instance.render('main');

        expect(result, 'Start L1 L2 L1 End');
      });
    });
  });
}
