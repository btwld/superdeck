import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_builder/src/assets/mermaid_generator.dart';

Future<void> main(List<String> args) async {
  final outputDir = args.isEmpty
      ? p.join('build', 'mermaid_defaults')
      : args.first;

  final targetDir = Directory(p.normalize(p.absolute(outputDir)));
  await targetDir.create(recursive: true);

  final samples = <String, String>{
    'flowchart': '''
flowchart LR
  Start([Start]) --> Check{Palette OK?}
  Check -->|Yes| Iterate[Iterate Styles]
  Check -->|No| Adjust[/Tweak Variables/]
  Iterate --> Review[[Review Deck]]
  Adjust --> Review
  Review --> Done((Done))
''',
    'sequence': '''
sequenceDiagram
  participant Author
  participant Theme
  participant Slide

  Author->>Theme: render(flowchart)
  Theme-->>Author: themed PNG
  Author->>Slide: embed asset
  Note right of Slide: review contrasts
''',
    'class': '''
classDiagram
  class MermaidGenerator {
    +generateAsset(graph, path)
    +dispose()
  }
  class MermaidTheme {
    +String background
    +String primary
    +Map toThemeVariables()
  }
  MermaidGenerator --> MermaidTheme
''',
    'pie': '''
pie title Default Theme Palette
  "Primary" : 40
  "Secondary" : 25
  "Accent" : 15
  "Neutral" : 10
  "Info" : 10
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

  final themes = ['default', 'dark'];

  for (final themeName in themes) {
    final generator = MermaidGenerator(
      configuration: {
        'theme': themeName,
        'look': 'classic',
        'securityLevel': 'strict',
        'handDrawnSeed': 17,
        'viewportWidth': 1280,
        'viewportHeight': 780,
        'deviceScaleFactor': 2,
        'timeout': 10,
        'extraCSS': '',
        'flowchart': {'htmlLabels': true},
        'sequence': {'mirrorActors': false},
        'class': {'htmlLabels': true},
      },
    );

    try {
      for (final entry in samples.entries) {
        final fileName = '${entry.key}_$themeName.png';
        final assetPath = p.join(targetDir.path, fileName);
        stdout.writeln('Generating $fileName');
        final bytes = await generator.generateAsset(entry.value, assetPath);
        await File(assetPath).writeAsBytes(bytes);
      }
    } finally {
      await generator.dispose();
    }
  }

  stdout
    ..writeln('\nSaved default Mermaid samples to:')
    ..writeln('  ${targetDir.path}')
    ..writeln('Files are grouped under built-in themes "default" and "dark".');
}
