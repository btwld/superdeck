import 'package:superdeck_builder/src/assets/color_utils.dart';
import 'package:superdeck_builder/src/assets/mermaid_theme.dart';
import 'package:test/test.dart';

void main() {
  group('MermaidTheme', () {
    group('presets', () {
      test('dark preset has correct values', () {
        expect(MermaidTheme.dark.darkMode, isTrue);
        expect(MermaidTheme.dark.background, equals('#0b0f14'));
        expect(MermaidTheme.dark.primary, equals('#0ea5e9'));
        expect(MermaidTheme.dark.text, equals('#e2e8f0'));
      });

      test('light preset has correct values', () {
        expect(MermaidTheme.light.darkMode, isFalse);
        expect(MermaidTheme.light.background, equals('#ffffff'));
        expect(MermaidTheme.light.primary, equals('#0066FF'));
        expect(MermaidTheme.light.text, equals('#1a1a1a'));
      });
    });

    group('toThemeVariables', () {
      test('includes all required core variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        // Core variables
        expect(vars['darkMode'], isTrue);
        expect(vars['primaryColor'], isNotNull);
        expect(vars['background'], isNotNull);
        expect(vars['textColor'], isNotNull);
        expect(vars['mainBkg'], isNotNull);
        expect(vars['fontFamily'], isNotNull);
        expect(vars['fontSize'], isNotNull);
      });

      test('includes flowchart-specific variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        expect(vars['nodeTextColor'], isNotNull);
        expect(vars['nodeBorder'], isNotNull);
        expect(vars['clusterBkg'], isNotNull);
        expect(vars['clusterBorder'], isNotNull);
        expect(vars['defaultLinkColor'], isNotNull);
        expect(vars['titleColor'], isNotNull);
        expect(vars['edgeLabelBackground'], isNotNull);
      });

      test('includes sequence diagram variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        expect(vars['actorBkg'], isNotNull);
        expect(vars['actorBorder'], isNotNull);
        expect(vars['actorTextColor'], isNotNull);
        expect(vars['signalColor'], isNotNull);
        expect(vars['signalTextColor'], isNotNull);
        expect(vars['noteBkgColor'], isNotNull);
        expect(vars['activationBkgColor'], isNotNull);
      });

      test('includes state diagram variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        expect(vars['stateBkg'], isNotNull);
        expect(vars['stateBorder'], isNotNull);
        expect(vars['stateTextColor'], isNotNull);
      });

      test('includes class diagram variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        expect(vars['classText'], isNotNull);
        expect(vars['classBkg'], isNotNull);
        expect(vars['classBorder'], isNotNull);
      });

      test('includes gantt chart variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        expect(vars['gridColor'], isNotNull);
        expect(vars['taskBkgColor'], isNotNull);
        expect(vars['taskTextColor'], isNotNull);
        expect(vars['activeTaskBorderColor'], isNotNull);
        expect(vars['doneTaskBkgColor'], isNotNull);
        expect(vars['todayLineColor'], isNotNull);
      });

      test('includes git diagram variables', () {
        final vars = MermaidTheme.dark.toThemeVariables();

        expect(vars['git0'], isNotNull);
        expect(vars['git1'], isNotNull);
        expect(vars['git7'], isNotNull);
      });
    });

    group('color derivation', () {
      test('dark mode derives lighter surface than background', () {
        final theme = MermaidTheme.dark;
        final vars = theme.toThemeVariables();

        final bgLum = ColorUtils.luminance(theme.background);
        final surfaceLum = ColorUtils.luminance(vars['mainBkg'] as String);

        expect(surfaceLum, greaterThan(bgLum));
      });

      test('light mode derives darker surface than background', () {
        final theme = MermaidTheme.light;
        final vars = theme.toThemeVariables();

        final bgLum = ColorUtils.luminance(theme.background);
        final surfaceLum = ColorUtils.luminance(vars['mainBkg'] as String);

        expect(surfaceLum, lessThan(bgLum));
      });

      test('border is darker than primary', () {
        final theme = MermaidTheme.dark;
        final vars = theme.toThemeVariables();

        final primaryLum = ColorUtils.luminance(theme.primary);
        final borderLum = ColorUtils.luminance(vars['primaryBorderColor'] as String);

        expect(borderLum, lessThan(primaryLum));
      });

      test('line color is muted version of text', () {
        final theme = MermaidTheme.dark;
        final vars = theme.toThemeVariables();

        // In dark mode, line should be lighter (muted)
        final textLum = ColorUtils.luminance(theme.text);
        final lineLum = ColorUtils.luminance(vars['lineColor'] as String);

        expect(lineLum, greaterThan(textLum));
      });
    });

    group('custom themes', () {
      test('allows custom color values', () {
        final theme = MermaidTheme(
          background: '#1a1a2e',
          primary: '#00ff88',
          text: '#ffffff',
          darkMode: true,
        );

        final vars = theme.toThemeVariables();
        expect(vars['background'], equals('#1a1a2e'));
        expect(vars['primaryColor'], equals('#00ff88'));
        expect(vars['textColor'], equals('#ffffff'));
      });

      test('custom theme derives consistent colors', () {
        final theme = MermaidTheme(
          background: '#2a2a3e',
          primary: '#ff6b6b',
          text: '#f0f0f0',
          darkMode: true,
        );

        final vars = theme.toThemeVariables();

        // Should derive surface from background
        expect(vars['mainBkg'], isNotNull);
        expect(vars['mainBkg'], isNot(equals(theme.background)));

        // Should derive border from primary
        expect(vars['primaryBorderColor'], isNotNull);
        expect(vars['primaryBorderColor'], isNot(equals(theme.primary)));
      });
    });

    group('equality and hashCode', () {
      test('equal themes have same hash code', () {
        final theme1 = MermaidTheme(
          background: '#000',
          primary: '#fff',
          text: '#888',
          darkMode: true,
        );

        final theme2 = MermaidTheme(
          background: '#000',
          primary: '#fff',
          text: '#888',
          darkMode: true,
        );

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('different themes are not equal', () {
        final theme1 = MermaidTheme.dark;
        final theme2 = MermaidTheme.light;

        expect(theme1, isNot(equals(theme2)));
        expect(theme1.hashCode, isNot(equals(theme2.hashCode)));
      });
    });

    group('toString', () {
      test('provides readable string representation', () {
        final theme = MermaidTheme.dark;
        final str = theme.toString();

        expect(str, contains('MermaidTheme'));
        expect(str, contains('background'));
        expect(str, contains('primary'));
        expect(str, contains('text'));
        expect(str, contains('darkMode'));
      });
    });
  });
}
