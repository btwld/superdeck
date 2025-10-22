import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_builder/src/assets/mermaid_generator.dart';
import 'package:superdeck_builder/src/assets/mermaid_theme.dart';

/// Renders a suite of Mermaid diagrams using the current theme presets and
/// writes the generated PNG assets to disk.
///
/// Usage:
/// ```
/// fvm dart run tool/generate_mermaid_samples.dart [outputDir]
/// ```
///
/// If no [outputDir] is supplied, assets are written to
/// `build/mermaid_theme_samples` relative to the repository root.
Future<void> main(List<String> args) async {
  final outputDir = args.isEmpty
      ? p.join('build', 'mermaid_theme_samples')
      : args.first;

  final targetDir = Directory(p.normalize(p.absolute(outputDir)));
  await targetDir.create(recursive: true);

  final samples = <String, String>{
    'flowchart': '''
flowchart LR
  Start([Start]) --> Check{Palette OK?}
  Check -->|Yes| Iterate[Iterate Styles]
  Check -->|No| Adjust[/Tweak Variables/]
  Iterate --> Mesh[[Review Deck]]
  Adjust --> Mesh
  Mesh --> End((Done))
''',
    'sequence': '''
sequenceDiagram
  participant Author
  participant Theme
  participant Slide

  Author->>Theme: render(flowchart)
  Theme-->>Author: themed PNG
  Author->>Slide: embed asset
  Note right of Slide: verify contrast levels
''',
    'class': '''
classDiagram
  class MermaidTheme {
    +String background
    +String primary
    +String text
    +Map toThemeVariables()
  }

  class MermaidGenerator {
    +generateAsset(graph, path)
    +dispose()
  }

  MermaidGenerator --> MermaidTheme
''',
    'pie': '''
pie title Theme Palette Allocation
  "Primary" : 40
  "Secondary" : 25
  "Tertiary" : 15
  "Surface" : 10
  "Accent" : 10
''',
    'timeline': '''
timeline
  title Theme QA
  section Pass
    Flowchart review : flowchart, 2024-07-01, 3d
    Sequence validation : sequence, after flowchart, 2d
  section Polish
    Palette tweaks : 2024-07-06, 2d
    Screenshot export : 2024-07-08, 1d
''',
  };

  final themes = <String, Map<String, dynamic>>{
    'dark': {
      'theme': MermaidTheme.dark,
      'extraCss':
          'body { background: #171b20; margin: 0; padding: 40px; }\npre.mermaid { display: inline-block; }',
    },
    'light': {
      'theme': MermaidTheme.light,
      'extraCss':
          'body { background: #ffffff; margin: 0; padding: 40px; }\npre.mermaid { display: inline-block; }',
    },
  };

  for (final entry in themes.entries) {
    final themeName = entry.key;
    final theme = entry.value['theme'] as MermaidTheme;
    final extraCss = entry.value['extraCss'] as String;
    final generator = MermaidGenerator(
      theme: theme,
      configuration: {'extraCSS': extraCss},
    );

    try {
      for (final sample in samples.entries) {
        final fileName = '${sample.key}_$themeName.png';
        final assetPath = p.join(targetDir.path, fileName);

        stdout.writeln('Generating $fileName');
        final bytes = await generator.generateAsset(sample.value, assetPath);
        await File(assetPath).writeAsBytes(bytes);
      }
    } finally {
      await generator.dispose();
    }
  }

  stdout
    ..writeln('\nSaved Mermaid sample images to:')
    ..writeln('  ${targetDir.path}')
    ..writeln(
      'Open the PNGs to visually inspect theme coverage across diagram types.',
    );
}
