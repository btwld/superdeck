import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// A widget capability that an application explicitly exposes to AI generation.
final class GenerationElementDescriptor {
  const GenerationElementDescriptor({
    required this.name,
    required this.description,
    required this.arguments,
    required this.argumentSchema,
    this.sourceArgument,
  });

  final String name;
  final String description;
  final String arguments;
  final ObjectSchema argumentSchema;
  final String? sourceArgument;
}

/// Allowlist and argument validator for generation-capable widget blocks.
final class GenerationElementCatalog {
  GenerationElementCatalog(Iterable<GenerationElementDescriptor> descriptors)
    : _descriptors = Map.unmodifiable({
        for (final descriptor in descriptors) descriptor.name: descriptor,
      });

  factory GenerationElementCatalog.builtIn({
    Iterable<GenerationElementDescriptor> custom = const [],
  }) {
    return GenerationElementCatalog([..._builtIns, ...custom]);
  }

  final Map<String, GenerationElementDescriptor> _descriptors;

  Iterable<String> get names => _descriptors.keys;

  Map<String, AckSchema<Object, Object>> get argumentProperties => {
    for (final descriptor in _descriptors.values)
      ...descriptor.argumentSchema.partial().properties,
  };

  List<String> validate(String name, Map<String, Object?> args) {
    final descriptor = _descriptors[name];
    if (descriptor == null) {
      return ['Widget "$name" is not registered for generation.'];
    }
    final allowed = descriptor.argumentSchema.properties.keys.toSet();
    final unexpected = args.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unexpected.isNotEmpty) {
      final allowedList = allowed.toList()..sort();
      return [
        'Widget "$name" has arguments from another widget. '
            'Remove unsupported arguments: ${unexpected.join(', ')}. '
            'Allowed arguments: ${allowedList.join(', ')}.',
      ];
    }
    try {
      descriptor.argumentSchema.parse(args);
      return const [];
    } catch (error) {
      return ['Widget "$name" has invalid arguments: $error'];
    }
  }

  Map<String, Object?> normalizeDraftArguments(
    String name,
    Map<String, Object?> args,
    String? source,
  ) {
    final descriptor = _descriptors[name];
    if (descriptor == null) return args;
    final allowed = descriptor.argumentSchema.properties.keys.toSet();
    final normalized = <String, Object?>{
      for (final entry in args.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
    final sourceArgument = descriptor.sourceArgument;
    if (sourceArgument == null || source == null || source.isEmpty) {
      return normalized;
    }
    return {...normalized, sourceArgument: source};
  }

  String formatForPrompt() {
    final entries = _descriptors.values
        .map((descriptor) {
          final sourceGuidance = descriptor.sourceArgument == null
              ? ''
              : '\n  Supplied plan source: `args.${descriptor.sourceArgument}`';
          return '- `${descriptor.name}`: ${descriptor.description}\n'
              '  Arguments: ${descriptor.arguments}$sourceGuidance';
        })
        .join('\n');
    return '''
Widget blocks use a nested `args` object. Choose exactly one catalog entry and
put only that entry's listed arguments inside `args`; never mix fields from
different widget types.
$entries''';
  }
}

final _builtIns = <GenerationElementDescriptor>[
  GenerationElementDescriptor(
    name: 'image',
    description: 'A supplied image asset, file, or URL.',
    arguments: 'src (required), fit?, width?, height?, scale?',
    argumentSchema: ImageDto.schema,
    sourceArgument: 'src',
  ),
  GenerationElementDescriptor(
    name: 'webview',
    description: 'A user-supplied absolute HTTP(S) page.',
    arguments:
        'url (required), title?, cacheKey?, allowedHosts?, showControls?, javascript?',
    argumentSchema: WebViewDto.schema,
    sourceArgument: 'url',
  ),
  GenerationElementDescriptor(
    name: 'dartpad',
    description: 'A user-supplied DartPad gist.',
    arguments: 'id (required), theme?, embed?, run?, cacheKey?',
    argumentSchema: DartPadDto.schema,
    sourceArgument: 'id',
  ),
];
