import 'dart:convert';

import 'package:flutter/services.dart';

import '../schemas/outline_schema.dart';
import '../services/generation_element_catalog.dart';
import '../services/source_grounding.dart';

/// Loads canonical slide examples and selects only the current composition.
final class AssetCompositionExampleLibrary {
  AssetCompositionExampleLibrary({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/ai_examples/slide_composition_examples.json';

  final AssetBundle _bundle;
  Map<String, Map<String, Object?>> _templates = const {};

  Iterable<String> get supportedCompositions => _templateForComposition.keys;

  Future<void> load() async {
    if (_templates.isNotEmpty) return;
    final decoded = jsonDecode(await _bundle.loadString(assetPath));
    if (decoded is! Map) {
      throw const FormatException(
        'Composition example asset must be an object.',
      );
    }
    _templates = {
      for (final entry in decoded.entries)
        entry.key.toString(): Map<String, Object?>.from(entry.value as Map),
    };
    final missing = _templateForComposition.values
        .where((name) => !_templates.containsKey(name))
        .toSet();
    if (missing.isNotEmpty) {
      throw FormatException(
        'Composition example asset is missing: ${missing.join(', ')}.',
      );
    }
  }

  Map<String, Object?> buildFor({
    required DeckPlanSlide current,
    required GenerationElementCatalog elementCatalog,
  }) {
    if (_templates.isEmpty) {
      throw StateError('Composition examples have not been loaded.');
    }
    final templateName = _templateForComposition[current.composition]!;
    final example = _clone(_templates[templateName]!);
    example['key'] = current.key;
    final options = Map<String, Object?>.from(example['options']! as Map);
    options['title'] = current.title;
    options['style'] = current.treatment;
    example['options'] = options;

    final element = current.elements?.firstOrNull;
    if (element != null) {
      _hydrateElement(
        example,
        element: element,
        elementCatalog: elementCatalog,
      );
    }
    if (current.composition == 'imageLeft') {
      _reverseDominantRow(example);
    }
    if (current.composition == 'metric') {
      _hydrateMetric(example, current);
    }
    return example;
  }
}

const _templateForComposition = <String, String>{
  'title': 'title',
  'content': 'content',
  'twoColumn': 'twoColumn',
  'threeColumn': 'threeColumn',
  'table': 'table',
  'quote': 'quote',
  'titleLeft': 'titleLeft',
  'imageLeft': 'imageSplit',
  'imageRight': 'imageSplit',
  'imageFullBleed': 'imageFullBleed',
  'metric': 'metric',
  'webview': 'webview',
  'dartpad': 'dartpad',
  'custom': 'custom',
};

Map<String, Object?> _clone(Map<String, Object?> value) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);

void _hydrateElement(
  Map<String, Object?> example, {
  required DeckPlanElement element,
  required GenerationElementCatalog elementCatalog,
}) {
  final plannedName = element.type == 'custom'
      ? element.widgetName
      : element.type;
  if (plannedName == null) return;
  final sections = example['sections'];
  if (sections is! List) return;
  for (final rawSection in sections) {
    if (rawSection is! Map) continue;
    final blocks = rawSection['blocks'];
    if (blocks is! List) continue;
    for (final rawBlock in blocks) {
      if (rawBlock is! Map || rawBlock['type'] != 'widget') continue;
      final templateName = rawBlock['name']?.toString();
      if (templateName != element.type &&
          templateName != '__WIDGET__' &&
          templateName != plannedName) {
        continue;
      }
      rawBlock['name'] = plannedName;
      final rawArgs = rawBlock['args'];
      final args = rawArgs is Map
          ? Map<String, Object?>.from(rawArgs)
          : <String, Object?>{};
      args.removeWhere((_, value) => value == '__SOURCE__');
      rawBlock['args'] = elementCatalog.normalizeDraftArguments(
        plannedName,
        args,
        element.source,
      );
    }
  }
}

void _reverseDominantRow(Map<String, Object?> example) {
  final sections = example['sections'];
  if (sections is! List) return;
  for (final rawSection in sections) {
    if (rawSection is! Map) continue;
    final blocks = rawSection['blocks'];
    if (blocks is List && blocks.length > 1) {
      rawSection['blocks'] = blocks.reversed.toList();
      return;
    }
  }
}

void _hydrateMetric(Map<String, Object?> example, DeckPlanSlide current) {
  final metric = extractAudienceNumericClaims([
    current.title,
    current.assertion,
    ...current.contentUnits,
    current.contentBrief,
  ]).firstOrNull;
  final sections = example['sections'];
  if (sections is! List) return;
  for (final rawSection in sections) {
    if (rawSection is! Map) continue;
    final blocks = rawSection['blocks'];
    if (blocks is! List) continue;
    for (final rawBlock in blocks) {
      if (rawBlock is! Map || rawBlock['content'] is! String) continue;
      rawBlock['content'] = (rawBlock['content'] as String).replaceAll(
        '__PLANNED_METRIC__',
        metric ?? 'PLANNED VALUE',
      );
    }
  }
}
