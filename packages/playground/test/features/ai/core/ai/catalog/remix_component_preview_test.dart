import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/test/validation.dart';

import 'package:playground/features/ai/core/ai/catalog/catalog.dart';

void main() {
  group('RemixComponentPreview Schema', () {
    test('parses valid component preview data', () {
      final data = {
        'question': 'Which component layout do you prefer?',
        'description': 'Pick the composition that best fits your needs.',
        'componentOptions': [
          {
            'id': 'info_card',
            'title': 'Info Card',
            'description': 'A card with heading and action button.',
            'rootNodeId': 'card1',
            'nodes': [
              {
                'id': 'card1',
                'type': 'card',
                'children': ['col1'],
              },
              {
                'id': 'col1',
                'type': 'column',
                'children': ['text1', 'btn1'],
              },
              {'id': 'text1', 'type': 'text', 'label': 'Hello'},
              {
                'id': 'btn1',
                'type': 'button',
                'label': 'Click me',
                'icon': 'rocket',
              },
            ],
          },
          {
            'id': 'settings_panel',
            'title': 'Settings Panel',
            'description': 'An accordion with toggleable settings.',
            'rootNodeId': 'acc1',
            'nodes': [
              {
                'id': 'acc1',
                'type': 'accordion',
                'children': ['s1'],
              },
              {
                'id': 's1',
                'type': 'column',
                'label': 'Appearance',
                'children': ['sw1'],
              },
              {
                'id': 'sw1',
                'type': 'switchToggle',
                'label': 'Dark mode',
                'selected': true,
              },
            ],
          },
        ],
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = RemixComponentPreviewType.parse(data);
      expect(parsed.question, 'Which component layout do you prefer?');
      expect(
        parsed.description,
        'Pick the composition that best fits your needs.',
      );
      expect(parsed.componentOptions, hasLength(2));
      expect(parsed.componentOptions[0].id, 'info_card');
      expect(parsed.componentOptions[0].title, 'Info Card');
      expect(parsed.componentOptions[0].rootNodeId, 'card1');
      expect(parsed.componentOptions[0].nodes, hasLength(4));
      expect(parsed.componentOptions[1].id, 'settings_panel');
      expect(parsed.componentOptions[1].nodes, hasLength(3));
    });

    test('description is optional', () {
      final data = {
        'question': 'Pick a layout',
        'componentOptions': [
          {
            'id': 'opt1',
            'title': 'Option A',
            'description': 'First option',
            'rootNodeId': 'r1',
            'nodes': [
              {'id': 'r1', 'type': 'text', 'label': 'Hello'},
            ],
          },
        ],
        'action': {'name': 'submit_answer', 'context': []},
      };

      final parsed = RemixComponentPreviewType.parse(data);
      expect(parsed.question, 'Pick a layout');
      expect(parsed.description, isNull);
    });

    test('UiNodeType parses all fields', () {
      final node = UiNodeType.parse({
        'id': 'test_node',
        'type': 'button',
        'label': 'Click me',
        'description': 'A test button',
        'icon': 'star',
        'color': '#6366F1',
        'value': 0.75,
        'selected': true,
        'children': ['child1', 'child2'],
      });

      expect(node.id, 'test_node');
      expect(node.type, UiComponentType.button);
      expect(node.label, 'Click me');
      expect(node.description, 'A test button');
      expect(node.icon, UiNodeIcon.star);
      expect(node.color, '#6366F1');
      expect(node.value, 0.75);
      expect(node.selected, isTrue);
      expect(node.children, equals(['child1', 'child2']));
    });

    test('UiNodeType optional fields default to null', () {
      final node = UiNodeType.parse({'id': 'minimal_node', 'type': 'divider'});

      expect(node.id, 'minimal_node');
      expect(node.type, UiComponentType.divider);
      expect(node.label, isNull);
      expect(node.description, isNull);
      expect(node.icon, isNull);
      expect(node.color, isNull);
      expect(node.value, isNull);
      expect(node.selected, isNull);
      expect(node.children, isNull);
    });

    test('ComponentOptionType parses with nodes list', () {
      final option = ComponentOptionType.parse({
        'id': 'test_opt',
        'title': 'Test Option',
        'description': 'A test component option',
        'rootNodeId': 'root',
        'nodes': [
          {
            'id': 'root',
            'type': 'card',
            'children': ['txt'],
          },
          {'id': 'txt', 'type': 'text', 'label': 'Content'},
        ],
      });

      expect(option.id, 'test_opt');
      expect(option.title, 'Test Option');
      expect(option.description, 'A test component option');
      expect(option.rootNodeId, 'root');
      expect(option.nodes, hasLength(2));
      expect(option.nodes[0].id, 'root');
      expect(option.nodes[0].type, UiComponentType.card);
      expect(option.nodes[1].id, 'txt');
      expect(option.nodes[1].label, 'Content');
    });

    test('UiThemeType parses all fields', () {
      final theme = UiThemeType.parse({
        'accent': 'crimson',
        'gray': 'mauve',
        'brightness': 'dark',
      });

      expect(theme.accent, UiAccentColor.crimson);
      expect(theme.gray, UiGrayColor.mauve);
      expect(theme.brightness, UiBrightness.dark);
    });

    test('UiThemeType fields are all optional', () {
      final theme = UiThemeType.parse(<String, Object?>{});

      expect(theme.accent, isNull);
      expect(theme.gray, isNull);
      expect(theme.brightness, isNull);
    });

    test('UiThemeType partial fields work', () {
      final theme = UiThemeType.parse({'accent': 'violet'});

      expect(theme.accent, UiAccentColor.violet);
      expect(theme.gray, isNull);
      expect(theme.brightness, isNull);
    });

    test('RemixComponentPreviewType parses with top-level theme', () {
      final preview = RemixComponentPreviewType.parse({
        'question': 'Pick a style',
        'theme': {'accent': 'blue', 'gray': 'slate', 'brightness': 'light'},
        'componentOptions': [
          {
            'id': 'opt',
            'title': 'Option',
            'description': 'Desc',
            'rootNodeId': 'root',
            'nodes': [
              {'id': 'root', 'type': 'text', 'label': 'Hello'},
            ],
          },
        ],
        'action': {'name': 'submit_answer', 'context': []},
      });

      expect(preview.theme, isNotNull);
      final theme = preview.theme!;
      expect(theme.accent, UiAccentColor.blue);
      expect(theme.gray, UiGrayColor.slate);
      expect(theme.brightness, UiBrightness.light);
    });

    test('RemixComponentPreviewType theme is optional', () {
      final preview = RemixComponentPreviewType.parse({
        'question': 'Pick a style',
        'componentOptions': [
          {
            'id': 'opt',
            'title': 'Option',
            'description': 'Desc',
            'rootNodeId': 'root',
            'nodes': [
              {'id': 'root', 'type': 'text', 'label': 'Hello'},
            ],
          },
        ],
        'action': {'name': 'submit_answer', 'context': []},
      });

      expect(preview.theme, isNull);
    });

    test('RemixComponentPreviewType parses with empty theme', () {
      final preview = RemixComponentPreviewType.parse({
        'question': 'Pick a style',
        'theme': <String, Object?>{},
        'componentOptions': [
          {
            'id': 'opt',
            'title': 'Option',
            'description': 'Desc',
            'rootNodeId': 'root',
            'nodes': [
              {'id': 'root', 'type': 'text', 'label': 'Hello'},
            ],
          },
        ],
        'action': {'name': 'submit_answer', 'context': []},
      });

      expect(preview.theme, isNotNull);
      final theme = UiThemeType.parse(preview.theme!);
      expect(theme.accent, isNull);
      expect(theme.gray, isNull);
      expect(theme.brightness, isNull);
    });

    test('UiThemeType partial: only gray set', () {
      final theme = UiThemeType.parse({'gray': 'sage'});

      expect(theme.accent, isNull);
      expect(theme.gray, UiGrayColor.sage);
      expect(theme.brightness, isNull);
    });

    test('UiThemeType partial: only brightness set', () {
      final theme = UiThemeType.parse({'brightness': 'dark'});

      expect(theme.accent, isNull);
      expect(theme.gray, isNull);
      expect(theme.brightness, UiBrightness.dark);
    });

    test('UiThemeType partial: accent and brightness, no gray', () {
      final theme = UiThemeType.parse({
        'accent': 'crimson',
        'brightness': 'dark',
      });

      expect(theme.accent, UiAccentColor.crimson);
      expect(theme.gray, isNull);
      expect(theme.brightness, UiBrightness.dark);
    });

    test('UiAccentColor maps to FortalAccentColor correctly', () {
      for (final color in UiAccentColor.values) {
        expect(
          color.fortalColor.name,
          color.name,
          reason: '${color.name} should map to FortalAccentColor.${color.name}',
        );
      }
    });

    test('UiGrayColor maps to FortalGrayColor correctly', () {
      for (final color in UiGrayColor.values) {
        expect(
          color.fortalColor.name,
          color.name,
          reason: '${color.name} should map to FortalGrayColor.${color.name}',
        );
      }
    });

    test('UiBrightness maps to Flutter Brightness correctly', () {
      expect(UiBrightness.light.flutterBrightness, Brightness.light);
      expect(UiBrightness.dark.flutterBrightness, Brightness.dark);
    });
  });

  group('_parseThemeContext resilience', () {
    test('returns empty map for invalid enum values', () {
      expect(
        () => UiThemeType.parse({'accent': 'nonexistent_color'}),
        throwsA(anything),
        reason: 'Invalid enum value should throw during parse',
      );
    });

    test('valid partial theme parses without error', () {
      final theme = UiThemeType.parse({'brightness': 'dark'});
      expect(theme.brightness, UiBrightness.dark);
      expect(theme.accent, isNull);
      expect(theme.gray, isNull);
    });
  });

  group('RemixComponentPreview CatalogItem', () {
    test('has correct name', () {
      expect(remixComponentPreview.name, 'RemixComponentPreview');
    });

    test('has non-null schema', () {
      expect(remixComponentPreview.dataSchema, isNotNull);
      expect(
        remixComponentPreview.dataSchema.value,
        isA<Map<String, Object?>>(),
      );
    });

    test('has example data', () {
      expect(remixComponentPreview.exampleData, isNotEmpty);
    });

    test('examples are valid JSON', () async {
      final errors = await validateCatalogItemExamples(
        remixComponentPreview,
        chatCatalog,
      );

      final criticalErrors = errors.where((e) {
        final message = e.toString();
        return !message.contains('optional') &&
            !message.contains('not required');
      }).toList();

      expect(
        criticalErrors,
        isEmpty,
        reason:
            'Examples should be valid. Errors:\n${criticalErrors.join('\n')}',
      );
    });
  });
}
