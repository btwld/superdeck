import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Service for managing deck schema validation and signature generation.
///
/// This service provides utilities for:
/// - Generating JSON schemas for LLM consumption
/// - Creating schema signatures for validation
/// - Validating deck data with signature verification
///
/// Use this service when integrating with LLMs that need to understand
/// and generate valid superdeck.json content.
class DeckSchemaService {
  DeckSchemaService._();

  static final _instance = DeckSchemaService._();

  /// Returns the singleton instance of [DeckSchemaService].
  static DeckSchemaService get instance => _instance;

  /// The current schema version.
  ///
  /// Increment this when making breaking changes to the schema.
  static const schemaVersion = '1.0.0';

  /// Cached schema signature.
  String? _cachedSignature;

  /// Cached JSON schema map.
  Map<String, dynamic>? _cachedJsonSchema;

  /// Returns the complete deck schema.
  ObjectSchema get deckSchema => Deck.schema;

  /// Returns the slide schema.
  ObjectSchema get slideSchema => Slide.schema;

  /// Returns the section block schema.
  ObjectSchema get sectionSchema => SectionBlock.schema;

  /// Returns the content block schema.
  ObjectSchema get contentBlockSchema => ContentBlock.schema;

  /// Returns the widget block schema.
  ObjectSchema get widgetBlockSchema => WidgetBlock.schema;

  /// Returns the deck configuration schema.
  ObjectSchema get configurationSchema => DeckConfiguration.schema;

  /// Generates the JSON Schema representation of the deck schema.
  ///
  /// This schema follows JSON Schema Draft-7 specification and can be
  /// used with LLMs for structured output generation.
  ///
  /// The schema includes:
  /// - All slide properties and nested block structures
  /// - Configuration options
  /// - Enum values for alignment, image fit, etc.
  ///
  /// Example:
  /// ```dart
  /// final jsonSchema = DeckSchemaService.instance.toJsonSchema();
  /// // Pass to LLM for structured output generation
  /// ```
  Map<String, dynamic> toJsonSchema() {
    if (_cachedJsonSchema != null) {
      return _cachedJsonSchema!;
    }

    _cachedJsonSchema = _buildJsonSchema();
    return _cachedJsonSchema!;
  }

  /// Generates a unique signature for the current schema version.
  ///
  /// The signature is a SHA-256 hash of the JSON schema structure,
  /// ensuring that any schema changes result in a different signature.
  ///
  /// Use this signature to:
  /// - Verify that LLM-generated content matches the expected schema version
  /// - Detect schema drift between client and server
  /// - Cache schema-dependent computations
  ///
  /// Example:
  /// ```dart
  /// final signature = DeckSchemaService.instance.generateSignature();
  /// // Include in API responses for validation
  /// ```
  String generateSignature() {
    if (_cachedSignature != null) {
      return _cachedSignature!;
    }

    final schemaJson = toJsonSchema();
    // Include version in signature to ensure version changes invalidate signature
    final signatureInput = jsonEncode({
      'version': schemaVersion,
      'schema': schemaJson,
    });

    _cachedSignature = generateContentHash(signatureInput, truncateLength: 16);
    return _cachedSignature!;
  }

  /// Validates deck data and returns a validation result.
  ///
  /// Returns a [DeckValidationResult] containing:
  /// - Whether validation passed
  /// - The parsed deck (if successful)
  /// - Validation errors (if failed)
  /// - The current schema signature
  ///
  /// Example:
  /// ```dart
  /// final result = DeckSchemaService.instance.validate(deckJson);
  /// if (result.isValid) {
  ///   final deck = result.deck;
  /// } else {
  ///   print('Errors: ${result.errors}');
  /// }
  /// ```
  DeckValidationResult validate(Map<String, dynamic> data) {
    final signature = generateSignature();

    try {
      final parseResult = Deck.safeParse(data);

      if (parseResult.isOk) {
        final deck = Deck.fromMap(data);
        return DeckValidationResult.success(
          deck: deck,
          signature: signature,
        );
      } else {
        final errors = _extractErrors(parseResult);
        return DeckValidationResult.failure(
          errors: errors,
          signature: signature,
        );
      }
    } catch (e) {
      return DeckValidationResult.failure(
        errors: [DeckValidationError(path: '', message: e.toString())],
        signature: signature,
      );
    }
  }

  /// Validates deck data with signature verification.
  ///
  /// Verifies that the provided signature matches the current schema signature,
  /// then validates the data. This ensures the data was generated with a
  /// compatible schema version.
  ///
  /// Example:
  /// ```dart
  /// final result = DeckSchemaService.instance.validateWithSignature(
  ///   data: deckJson,
  ///   expectedSignature: 'abc123...',
  /// );
  ///
  /// if (result.signatureMismatch) {
  ///   print('Schema version mismatch!');
  /// }
  /// ```
  DeckValidationResult validateWithSignature({
    required Map<String, dynamic> data,
    required String expectedSignature,
  }) {
    final currentSignature = generateSignature();

    if (expectedSignature != currentSignature) {
      return DeckValidationResult.failure(
        errors: [
          DeckValidationError(
            path: '',
            message: 'Schema signature mismatch. '
                'Expected: $expectedSignature, '
                'Current: $currentSignature',
          ),
        ],
        signature: currentSignature,
        signatureMismatch: true,
      );
    }

    return validate(data);
  }

  /// Generates a prompt-friendly schema description for LLMs.
  ///
  /// Returns a formatted string containing the JSON schema and signature
  /// that can be included in LLM prompts for structured output generation.
  ///
  /// Example:
  /// ```dart
  /// final prompt = '''
  /// Generate a superdeck.json file with the following schema:
  /// ${DeckSchemaService.instance.toPromptSchema()}
  ///
  /// Create a presentation about Flutter widgets.
  /// ''';
  /// ```
  String toPromptSchema() {
    final jsonSchema = toJsonSchema();
    final signature = generateSignature();

    return '''
## SuperDeck JSON Schema

**Schema Version:** $schemaVersion
**Schema Signature:** $signature

### Schema Definition

```json
${prettyJson(jsonSchema)}
```

### Instructions

1. Generate a valid JSON object matching this schema
2. Include the signature "$signature" in your response for validation
3. Ensure all required fields are present
4. Use valid enum values for alignment, image fit, etc.
''';
  }

  /// Clears cached schema data.
  ///
  /// Call this if you need to regenerate the schema (e.g., after
  /// dynamic schema modifications).
  void clearCache() {
    _cachedSignature = null;
    _cachedJsonSchema = null;
  }

  /// Builds the complete JSON schema from ack schemas.
  Map<String, dynamic> _buildJsonSchema() {
    return {
      '\$schema': 'https://json-schema.org/draft-07/schema#',
      'title': 'SuperDeck',
      'description': 'Schema for superdeck.json presentation files',
      'version': schemaVersion,
      'type': 'object',
      'required': ['slides'],
      'properties': {
        'slides': {
          'type': 'array',
          'description': 'List of slides in the presentation',
          'items': _slideSchema(),
        },
        'configuration': _configurationSchema(),
      },
      'additionalProperties': true,
    };
  }

  Map<String, dynamic> _slideSchema() {
    return {
      'type': 'object',
      'description': 'A single slide in the presentation',
      'required': ['key'],
      'properties': {
        'key': {
          'type': 'string',
          'description': 'Unique identifier for this slide',
        },
        'options': _slideOptionsSchema(),
        'sections': {
          'type': 'array',
          'description': 'Content sections within this slide',
          'items': _sectionBlockSchema(),
        },
        'comments': {
          'type': 'array',
          'description': 'Speaker notes for this slide',
          'items': {'type': 'string'},
        },
      },
      'additionalProperties': true,
    };
  }

  Map<String, dynamic> _slideOptionsSchema() {
    return {
      'type': 'object',
      'description': 'Configuration options for the slide',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'Title of the slide',
        },
        'style': {
          'type': 'string',
          'description': 'Style template to apply to this slide',
        },
      },
      'additionalProperties': true,
    };
  }

  Map<String, dynamic> _sectionBlockSchema() {
    return {
      'type': 'object',
      'description': 'A section containing multiple content blocks',
      'required': ['type'],
      'properties': {
        'type': {
          'type': 'string',
          'const': 'section',
          'description': 'Block type identifier',
        },
        'align': _alignmentSchema(),
        'flex': {
          'type': 'integer',
          'description': 'Flex weight for layout (default: 1)',
          'default': 1,
        },
        'scrollable': {
          'type': 'boolean',
          'description': 'Whether content is scrollable',
          'default': false,
        },
        'blocks': {
          'type': 'array',
          'description': 'Child blocks within this section',
          'items': {
            'oneOf': [
              _contentBlockSchema(),
              _widgetBlockSchema(),
            ],
          },
        },
      },
      'additionalProperties': true,
    };
  }

  Map<String, dynamic> _contentBlockSchema() {
    return {
      'type': 'object',
      'description': 'A block containing markdown content',
      'required': ['type'],
      'properties': {
        'type': {
          'type': 'string',
          'enum': ['block', 'column'],
          'description': 'Block type (column is legacy, use block)',
        },
        'align': _alignmentSchema(),
        'flex': {
          'type': 'integer',
          'description': 'Flex weight for layout',
          'default': 1,
        },
        'scrollable': {
          'type': 'boolean',
          'description': 'Whether content is scrollable',
          'default': false,
        },
        'content': {
          'type': 'string',
          'description': 'Markdown content to display',
        },
      },
      'additionalProperties': true,
    };
  }

  Map<String, dynamic> _widgetBlockSchema() {
    return {
      'type': 'object',
      'description': 'A block containing a custom Flutter widget',
      'required': ['type', 'name'],
      'properties': {
        'type': {
          'type': 'string',
          'const': 'widget',
          'description': 'Block type identifier',
        },
        'name': {
          'type': 'string',
          'description': 'Name of the widget to render',
        },
        'align': _alignmentSchema(),
        'flex': {
          'type': 'integer',
          'description': 'Flex weight for layout',
          'default': 1,
        },
        'scrollable': {
          'type': 'boolean',
          'description': 'Whether content is scrollable',
          'default': false,
        },
      },
      'additionalProperties': true,
    };
  }

  Map<String, dynamic> _alignmentSchema() {
    return {
      'type': 'string',
      'description': 'Content alignment within the block',
      'enum': [
        'topLeft',
        'topCenter',
        'topRight',
        'centerLeft',
        'center',
        'centerRight',
        'bottomLeft',
        'bottomCenter',
        'bottomRight',
      ],
    };
  }

  Map<String, dynamic> _configurationSchema() {
    return {
      'type': 'object',
      'description': 'Deck configuration settings',
      'properties': {
        'projectDir': {
          'type': 'string',
          'description': 'Project directory path',
        },
        'slidesPath': {
          'type': 'string',
          'description': 'Path to the slides markdown file',
        },
        'outputDir': {
          'type': 'string',
          'description': 'Output directory for generated files',
        },
        'assetsPath': {
          'type': 'string',
          'description': 'Path to generated assets',
        },
      },
      'additionalProperties': true,
    };
  }

  List<DeckValidationError> _extractErrors(SchemaResult result) {
    final errors = <DeckValidationError>[];

    if (result.isFail) {
      final error = result.getError();
      if (error != null) {
        errors.add(DeckValidationError(
          path: error.path,
          message: error.message,
        ));
      }
    }

    return errors;
  }
}

/// Result of deck validation.
class DeckValidationResult {
  /// Creates a successful validation result.
  DeckValidationResult.success({
    required Deck deck,
    required this.signature,
  })  : isValid = true,
        _deck = deck,
        errors = const [],
        signatureMismatch = false;

  /// Creates a failed validation result.
  DeckValidationResult.failure({
    required this.errors,
    required this.signature,
    this.signatureMismatch = false,
  })  : isValid = false,
        _deck = null;

  /// Whether the validation passed.
  final bool isValid;

  /// The validated deck (null if validation failed).
  final Deck? _deck;

  /// List of validation errors (empty if validation passed).
  final List<DeckValidationError> errors;

  /// The current schema signature.
  final String signature;

  /// Whether the signature validation failed.
  final bool signatureMismatch;

  /// Returns the validated deck.
  ///
  /// Throws [StateError] if validation failed.
  Deck get deck {
    if (_deck == null) {
      throw StateError('Cannot access deck: validation failed');
    }
    return _deck;
  }

  /// Returns the validated deck or null if validation failed.
  Deck? get deckOrNull => _deck;

  /// Converts the result to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'signature': signature,
      'signatureMismatch': signatureMismatch,
      if (_deck != null) 'deck': _deck.toMap(),
      if (errors.isNotEmpty)
        'errors': errors.map((e) => e.toMap()).toList(),
    };
  }
}

/// A validation error from deck parsing.
class DeckValidationError {
  const DeckValidationError({
    required this.path,
    required this.message,
  });

  /// The JSON path where the error occurred.
  final String path;

  /// The error message.
  final String message;

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'message': message,
    };
  }

  @override
  String toString() => 'DeckValidationError($path: $message)';
}
