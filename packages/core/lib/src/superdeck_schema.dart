import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:crypto/crypto.dart';

import 'models/block_model.dart';
import 'models/deck_model.dart';
import 'models/slide_model.dart';
import 'deck_configuration.dart';

/// Provides the complete superdeck.json schema with validation,
/// JSON Schema export, and signature generation for LLM integration.
///
/// This class is designed to work with LLMs by providing:
/// - A complete JSON Schema representation of the deck structure
/// - A unique signature for the schema version
/// - Validation methods for deck data
/// - Methods for generating LLM-friendly prompts
class SuperdeckSchema {
  SuperdeckSchema._();

  /// The main deck schema with full descriptions for LLM understanding.
  static ObjectSchema get deckSchema => Deck.schema;

  /// Schema for individual slides.
  static ObjectSchema get slideSchema => Slide.schema;

  /// Schema for slide options/configuration.
  static ObjectSchema get slideOptionsSchema => SlideOptions.schema;

  /// Schema for section blocks (horizontal layout containers).
  static ObjectSchema get sectionBlockSchema => SectionBlock.schema;

  /// Schema for content blocks (markdown content).
  static ObjectSchema get contentBlockSchema => ContentBlock.schema;

  /// Schema for widget blocks (custom Flutter widgets).
  static ObjectSchema get widgetBlockSchema => WidgetBlock.schema;

  /// Discriminated schema for all block types.
  static AckSchema<Map<String, Object?>> get blockSchema =>
      Block.discriminatedSchema;

  /// Schema for deck configuration.
  static ObjectSchema get configurationSchema => DeckConfiguration.schema;

  /// Content alignment enum values for LLM reference.
  static List<String> get contentAlignmentValues =>
      ContentAlignment.values.map((e) => e.name).toList();

  /// Converts the deck schema to a JSON Schema representation.
  ///
  /// This can be used to provide structured output definitions to LLMs
  /// that support JSON Schema (like Gemini, GPT-4, Claude, etc.).
  static Map<String, Object?> toJsonSchema() {
    return deckSchema.toJsonSchema().toJson();
  }

  /// Converts the deck schema to a formatted JSON string.
  static String toJsonSchemaString({bool pretty = true}) {
    final schema = toJsonSchema();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(schema);
    }
    return jsonEncode(schema);
  }

  /// Generates a unique signature for the current schema version.
  ///
  /// This signature can be used to:
  /// - Verify that an LLM-generated response matches the expected schema
  /// - Track schema version changes
  /// - Cache schema-dependent operations
  ///
  /// The signature is a SHA-256 hash of the JSON Schema representation.
  static String generateSignature() {
    final schemaJson = toJsonSchemaString(pretty: false);
    final bytes = utf8.encode(schemaJson);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a short signature (first 8 characters) for display purposes.
  static String generateShortSignature() {
    return generateSignature().substring(0, 8);
  }

  /// Validates a deck JSON map against the schema.
  ///
  /// Returns a [SchemaResult] that can be checked for success or failure.
  static SchemaResult<Map<String, Object?>> validate(Map<String, dynamic> map) {
    return deckSchema.safeParse(map);
  }

  /// Validates a deck JSON map and throws on error.
  ///
  /// Throws [SchemaError] if validation fails.
  static void validateOrThrow(Map<String, dynamic> map) {
    deckSchema.parse(map);
  }

  /// Parses and validates a JSON string as a deck.
  ///
  /// Returns a [SchemaResult] with the parsed deck or validation errors.
  static SchemaResult<Deck> parseJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Deck.safeParse(map);
    } on FormatException catch (e) {
      return SchemaResult.fail(
        SchemaError(
          value: jsonString,
          message: 'Invalid JSON: ${e.message}',
        ),
      );
    }
  }

  /// Generates an LLM-friendly prompt describing the schema.
  ///
  /// This prompt can be embedded in system messages or user prompts
  /// to help LLMs understand the expected output format.
  static String generateSchemaPrompt() {
    final signature = generateShortSignature();
    final schemaJson = toJsonSchemaString(pretty: true);

    return '''
# Superdeck JSON Schema (signature: $signature)

You are generating a superdeck.json file for a presentation. The output must conform to the following JSON Schema:

```json
$schemaJson
```

## Structure Overview

A deck contains:
- **slides**: An array of slide objects, ordered by display sequence
- **configuration**: Optional configuration for file paths

Each slide contains:
- **key**: A unique identifier (typically 8 characters)
- **options**: Optional settings like title, style, and custom arguments
- **sections**: An array of section blocks (arranged vertically)
- **comments**: Optional speaker notes

Each section contains:
- **type**: Must be "section"
- **blocks**: Child blocks arranged horizontally
- **flex**: Layout weight (default: 1)
- **align**: Content alignment
- **scrollable**: Whether content scrolls

Blocks can be:
1. **Content Block** (type: "block"): Displays markdown content
2. **Widget Block** (type: "widget"): Renders a custom widget by name
3. **Section Block** (type: "section"): Contains child blocks

## Content Alignment Values
${contentAlignmentValues.join(', ')}

## Example

```json
{
  "slides": [
    {
      "key": "abc12345",
      "options": {"style": "title"},
      "sections": [
        {
          "type": "section",
          "flex": 1,
          "blocks": [
            {
              "type": "block",
              "align": "center",
              "flex": 1,
              "content": "# Welcome\\n\\nThis is my presentation"
            }
          ]
        }
      ],
      "comments": ["Opening slide"]
    }
  ],
  "configuration": {}
}
```

When generating output, include the schema signature in your response to confirm compliance: [schema:$signature]
''';
  }

  /// Validates that a response contains the expected schema signature.
  ///
  /// Returns true if the response contains `[schema:<signature>]` where
  /// signature matches the current schema version.
  static bool verifyResponseSignature(String response) {
    final signature = generateShortSignature();
    return response.contains('[schema:$signature]');
  }

  /// Extracts JSON from an LLM response that may contain additional text.
  ///
  /// Looks for JSON content between ```json and ``` markers, or returns
  /// the entire content if it appears to be valid JSON.
  static String? extractJsonFromResponse(String response) {
    // Try to find JSON in code blocks
    final codeBlockPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = codeBlockPattern.firstMatch(response);
    if (match != null) {
      return match.group(1)?.trim();
    }

    // Try to find raw JSON (starts with { and ends with })
    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    // Try to find JSON array (starts with [ and ends with ])
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      return trimmed;
    }

    return null;
  }

  /// Parses an LLM response and validates it as a deck.
  ///
  /// This method:
  /// 1. Extracts JSON from the response
  /// 2. Validates it against the schema
  /// 3. Returns the parsed deck or validation errors
  static SchemaResult<Deck> parseResponse(String response) {
    final json = extractJsonFromResponse(response);
    if (json == null) {
      return SchemaResult.fail(
        SchemaError(
          value: response,
          message: 'Could not extract valid JSON from response',
        ),
      );
    }
    return parseJson(json);
  }

  /// Gets schema information as a structured map for debugging/inspection.
  static Map<String, Object?> getSchemaInfo() {
    return {
      'signature': generateSignature(),
      'shortSignature': generateShortSignature(),
      'version': '1.0.0',
      'schemas': {
        'deck': 'Deck.schema',
        'slide': 'Slide.schema',
        'slideOptions': 'SlideOptions.schema',
        'sectionBlock': 'SectionBlock.schema',
        'contentBlock': 'ContentBlock.schema',
        'widgetBlock': 'WidgetBlock.schema',
        'configuration': 'DeckConfiguration.schema',
      },
      'contentAlignments': contentAlignmentValues,
    };
  }
}
