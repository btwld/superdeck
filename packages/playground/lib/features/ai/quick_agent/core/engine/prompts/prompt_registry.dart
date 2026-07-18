import 'package:dotprompt_dart/dotprompt_dart.dart';
// ignore: implementation_imports, DotPromptPartialResolver not exported in public API
import 'package:dotprompt_dart/src/partial_resolver.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../../constants/paths.dart';

/// Loads and renders dotprompt templates from Flutter assets.
class PromptRegistry {
  PromptRegistry._();

  static final instance = PromptRegistry._();

  final Map<String, String> _prompts = {};
  final Map<String, String> _partials = {};
  bool _loaded = false;
  Future<void>? _loading;

  Future<void> load() {
    if (_loaded) {
      return Future.value();
    }
    if (_loading != null) {
      return _loading!;
    }
    _loading = _loadInternal().catchError((Object error, StackTrace stack) {
      _loading = null;
      _loaded = false;
      Error.throwWithStackTrace(error, stack);
    });
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
