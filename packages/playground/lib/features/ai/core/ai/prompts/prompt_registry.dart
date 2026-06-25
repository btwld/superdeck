import 'package:dotprompt_dart/dotprompt_dart.dart';
// ignore: implementation_imports, DotPromptPartialResolver not exported in public API
import 'package:dotprompt_dart/src/partial_resolver.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:playground/features/ai/core/constants/paths.dart';

/// Loads and renders dotprompt templates from Flutter assets.
class PromptRegistry {
  PromptRegistry._();

  static final instance = PromptRegistry._();

  final Map<String, String> _prompts = {};
  final Map<String, String> _partials = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  /// Loads prompts from a map for testing purposes.
  ///
  /// This bypasses asset loading and directly sets the prompts.
  void loadForTest({
    Map<String, String> prompts = const {},
    Map<String, String> partials = const {},
  }) {
    assert(() {
      return true;
    }(), 'loadForTest should only be called in tests');
    _loading = null;
    _prompts.clear();
    _partials.clear();
    _prompts.addAll(prompts);
    _partials.addAll(partials);
    _loaded = true;
  }

  /// Resets the registry to unloaded state (for testing).
  void reset() {
    assert(() {
      return true;
    }(), 'reset should only be called in tests');
    _prompts.clear();
    _partials.clear();
    _loaded = false;
    _loading = null;
  }

  Future<void> load() {
    if (_loaded) {
      return Future.value();
    }
    if (_loading != null) {
      return _loading!;
    }
    _loading = _loadInternal();
    return _loading!;
  }

  Future<void> _loadInternal() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    // Sort paths for deterministic loading order
    final promptPaths =
        manifest
            .listAssets()
            .where(
              (assetPath) =>
                  assetPath.startsWith(Paths.promptsDir) &&
                  assetPath.endsWith('.prompt'),
            )
            .toList()
          ..sort();

    for (final assetPath in promptPaths) {
      final content = await rootBundle.loadString(assetPath);
      final name = _nameFromAssetPath(assetPath);
      if (_isPartial(assetPath)) {
        _partials[name] = content;
      } else {
        _prompts[name] = content;
      }
    }

    _loaded = true;
  }

  String render(
    String name, {
    Map<String, dynamic> input = const {},
    List<Map<String, dynamic>> messages = const [],
    Map<String, dynamic>? context,
    dynamic docs,
  }) {
    if (!_loaded) {
      throw StateError('PromptRegistry not loaded.');
    }

    final content = _prompts[name];
    if (content == null || content.trim().isEmpty) {
      throw StateError('Prompt not found: $name');
    }

    final prompt = DotPrompt(
      content,
      partialResolver: _AssetPartialResolver(_partials),
    );
    return prompt.render(
      input: input,
      messages: messages,
      context: context,
      docs: docs,
    );
  }

  static bool _isPartial(String assetPath) {
    return assetPath.contains('/partials/');
  }

  static String _nameFromAssetPath(String assetPath) {
    final base = path.basenameWithoutExtension(assetPath);
    return base.startsWith('_') ? base.substring(1) : base;
  }
}

class _AssetPartialResolver implements DotPromptPartialResolver {
  _AssetPartialResolver(this._partials);

  final Map<String, String> _partials;

  @override
  String? resolve(String name) => _partials[name];
}
