import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../constants/paths.dart';
import '../../debug_logger.dart';

/// Loads example prompt/result pairs from assets for few-shot learning.
///
/// Examples are stored in `assets/examples/` as pairs:
/// - `{name}_prompt.txt` - The input prompt
/// - `{name}_deck.json` - The expected output
///
/// These are formatted and injected into the system prompt to guide
/// the AI's output format and quality.
class ExamplesLoader {
  ExamplesLoader._();

  static final instance = ExamplesLoader._();

  final _examples = <DeckExample>[];
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;
  List<DeckExample> get examples => List.unmodifiable(_examples);

  /// Loads all example pairs from assets.
  Future<void> load() {
    if (_loaded) return Future.value();
    if (_loading != null) return _loading!;

    _loading = _loadInternal().catchError((error) {
      _loading = null;
      throw error;
    });
    return _loading!;
  }

  Future<void> _loadInternal() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    // Find all prompt files in examples directory and sort for deterministic order
    // Note: Uses examplesAssetsDir (const) for asset manifest lookup, not examplesDir (runtime)
    final promptPaths =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith(Paths.examplesAssetsDir) &&
                  path.endsWith('_prompt.txt'),
            )
            .toList()
          ..sort();

    for (final promptPath in promptPaths) {
      // Derive deck path from prompt path
      // e.g., assets/examples/coffee_prompt.txt -> assets/examples/coffee_deck.json
      final deckPath = promptPath.replaceAll('_prompt.txt', '_deck.json');

      try {
        final prompt = await rootBundle.loadString(promptPath);
        final result = await rootBundle.loadString(deckPath);

        // Extract name from path (e.g., "coffee" from "coffee_prompt.txt")
        final name = p
            .basenameWithoutExtension(promptPath)
            .replaceAll('_prompt', '');

        _examples.add(
          DeckExample(name: name, prompt: prompt.trim(), result: result.trim()),
        );
      } catch (e, stack) {
        debugLog.error(
          'EXAMPLES',
          'Failed to load example pair for $promptPath: $e',
          stack,
        );
        continue;
      }
    }

    if (_examples.isEmpty && promptPaths.isNotEmpty) {
      debugLog.error('EXAMPLES', 'No examples loaded despite finding prompts');
    }

    _loaded = true;
  }

  /// Formats all examples as a string for inclusion in prompts.
  ///
  /// Format:
  /// ```
  /// ## Examples
  ///
  /// **Input:**
  /// {prompt content}
  ///
  /// **Output:**
  /// ```json
  /// {result content}
  /// ```
  ///
  /// ## Output
  /// Generate a JSON response based on the user's input above.
  /// ```
  String formatForPrompt() {
    if (_examples.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Examples');
    buffer.writeln();
    buffer.writeln(
      'Below are examples of input prompts and their expected JSON outputs. '
      'Study these carefully to understand the exact format and structure required.',
    );
    buffer.writeln();

    for (final example in _examples) {
      buffer.writeln('**Input:**');
      buffer.writeln(example.prompt);
      buffer.writeln();
      buffer.writeln('**Output:**');
      buffer.writeln('```json');
      buffer.writeln(example.result);
      buffer.writeln('```');
      buffer.writeln();
    }

    // Add output section to guide the AI response
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('## Output');
    buffer.writeln();
    buffer.writeln(
      'Now generate a JSON response based on the user\'s input. '
      'Follow the exact structure shown in the examples above.',
    );

    return buffer.toString();
  }
}

/// A single example consisting of an input prompt and expected output.
class DeckExample {
  const DeckExample({
    required this.name,
    required this.prompt,
    required this.result,
  });

  final String name;
  final String prompt;
  final String result;
}
