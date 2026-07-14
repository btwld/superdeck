import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

class GoogleSchemaAdapterError {
  const GoogleSchemaAdapterError(this.message, {required this.path});

  final String message;
  final List<String> path;

  @override
  String toString() => 'Error at path "${path.join('/')}": $message';
}

class GoogleSchemaAdapterResult {
  const GoogleSchemaAdapterResult(this.schema, this.errors);

  final google_ai.Schema? schema;
  final List<GoogleSchemaAdapterError> errors;
}

class GoogleSchemaAdapter {
  final _errors = <GoogleSchemaAdapterError>[];

  GoogleSchemaAdapterResult adapt(dsb.Schema schema) {
    _errors.clear();
    final googleSchema = _adapt(schema.value, ['#']);
    return GoogleSchemaAdapterResult(googleSchema, List.unmodifiable(_errors));
  }

  google_ai.Schema? _adapt(Map<String, Object?> schema, List<String> path) {
    _checkUnsupportedKeywords(schema, path);

    final type = _schemaType(schema, path);
    if (type == null) return null;

    return switch (type) {
      'object' => _adaptObject(schema, path),
      'array' => _adaptArray(schema, path),
      'string' => _adaptString(schema),
      'number' => _adaptScalar(google_ai.Type.number, schema, path),
      'integer' => _adaptScalar(google_ai.Type.integer, schema, path),
      'boolean' => _adaptScalar(google_ai.Type.boolean, schema, path),
      'null' => google_ai.Schema(
        type: google_ai.Type.object,
        nullable: true,
        description: _description(schema),
      ),
      _ => _unsupportedType(type, path),
    };
  }

  String? _schemaType(Map<String, Object?> schema, List<String> path) {
    final type = schema['type'];
    if (type is String) return type;
    if (type is List) {
      if (type.isEmpty) {
        _errors.add(
          GoogleSchemaAdapterError(
            'Schema has an empty "type" array.',
            path: path,
          ),
        );
        return null;
      }
      final firstType = type.first.toString();
      if (type.length > 1) {
        _errors.add(
          GoogleSchemaAdapterError(
            'Multiple types found (${type.join(', ')}). Only the first type '
            '"$firstType" will be used.',
            path: path,
          ),
        );
      }
      return firstType;
    }
    if (schema.containsKey('properties')) return 'object';
    if (schema.containsKey('items')) return 'array';

    _errors.add(
      GoogleSchemaAdapterError(
        'Schema must have a "type" or be implicitly typed with "properties" '
        'or "items".',
        path: path,
      ),
    );
    return null;
  }

  google_ai.Schema _adaptObject(
    Map<String, Object?> schema,
    List<String> path,
  ) {
    final properties = <String, google_ai.Schema>{};
    final rawProperties = schema['properties'];
    if (rawProperties is Map) {
      for (final entry in rawProperties.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map<String, Object?>) {
          final adapted = _adapt(value, [...path, 'properties', key]);
          if (adapted != null) properties[key] = adapted;
        }
      }
    }

    return google_ai.Schema(
      type: google_ai.Type.object,
      properties: properties,
      required: _stringList(schema['required']),
      description: _description(schema),
    );
  }

  google_ai.Schema? _adaptArray(
    Map<String, Object?> schema,
    List<String> path,
  ) {
    final items = schema['items'];
    if (items is! Map<String, Object?>) {
      _errors.add(
        GoogleSchemaAdapterError(
          'Array schema must have an "items" property.',
          path: path,
        ),
      );
      return null;
    }

    final adaptedItems = _adapt(items, [...path, 'items']);
    if (adaptedItems == null) return null;

    return google_ai.Schema(
      type: google_ai.Type.array,
      items: adaptedItems,
      description: _description(schema),
      minItems: _integerKeyword(schema['minItems']),
      maxItems: _integerKeyword(schema['maxItems']),
    );
  }

  google_ai.Schema _adaptString(Map<String, Object?> schema) {
    return google_ai.Schema(
      type: google_ai.Type.string,
      format: schema['format'] as String? ?? '',
      enum$: _stringList(schema['enum']),
      description: _description(schema),
      minLength: _integerKeyword(schema['minLength']),
      maxLength: _integerKeyword(schema['maxLength']),
      pattern: schema['pattern'] as String? ?? '',
    );
  }

  google_ai.Schema _adaptScalar(
    google_ai.Type type,
    Map<String, Object?> schema,
    List<String> path,
  ) {
    final isInteger = type == google_ai.Type.integer;
    var minimum = _numericBound(schema['minimum']);
    var maximum = _numericBound(schema['maximum']);

    if (schema['exclusiveMinimum'] case final num exclusiveMinimum) {
      if (isInteger) {
        final inclusiveMinimum = exclusiveMinimum.floorToDouble() + 1;
        minimum = minimum == null
            ? inclusiveMinimum
            : minimum > inclusiveMinimum
            ? minimum
            : inclusiveMinimum;
      } else {
        _reportUnsupportedKeyword('exclusiveMinimum', path);
      }
    }

    if (schema['exclusiveMaximum'] case final num exclusiveMaximum) {
      if (isInteger) {
        final inclusiveMaximum = exclusiveMaximum.ceilToDouble() - 1;
        maximum = maximum == null
            ? inclusiveMaximum
            : maximum < inclusiveMaximum
            ? maximum
            : inclusiveMaximum;
      } else {
        _reportUnsupportedKeyword('exclusiveMaximum', path);
      }
    }

    return google_ai.Schema(
      type: type,
      description: _description(schema),
      minimum: minimum,
      maximum: maximum,
    );
  }

  double? _numericBound(Object? value) => switch (value) {
    num value => value.toDouble(),
    _ => null,
  };

  int _integerKeyword(Object? value) => switch (value) {
    num value => value.toInt(),
    _ => 0,
  };

  google_ai.Schema? _unsupportedType(String type, List<String> path) {
    _errors.add(
      GoogleSchemaAdapterError('Unsupported schema type "$type".', path: path),
    );
    return null;
  }

  void _checkUnsupportedKeywords(
    Map<String, Object?> schema,
    List<String> path,
  ) {
    const unsupportedKeywords = {
      '\$comment',
      'default',
      'examples',
      'deprecated',
      'readOnly',
      'writeOnly',
      '\$defs',
      '\$ref',
      '\$anchor',
      '\$dynamicAnchor',
      '\$id',
      '\$schema',
      'allOf',
      'anyOf',
      'oneOf',
      'not',
      'if',
      'then',
      'else',
      'dependentSchemas',
      'const',
      'additionalProperties',
      'patternProperties',
      'dependentRequired',
      'unevaluatedProperties',
      'propertyNames',
      'minProperties',
      'maxProperties',
      'prefixItems',
      'unevaluatedItems',
      'contains',
      'minContains',
      'maxContains',
      'uniqueItems',
      'multipleOf',
    };

    for (final keyword in unsupportedKeywords) {
      if (schema.containsKey(keyword)) {
        _errors.add(
          GoogleSchemaAdapterError(
            'Unsupported keyword "$keyword". It will be ignored.',
            path: path,
          ),
        );
      }
    }
  }

  void _reportUnsupportedKeyword(String keyword, List<String> path) {
    _errors.add(
      GoogleSchemaAdapterError(
        'Unsupported keyword "$keyword". It will be ignored.',
        path: path,
      ),
    );
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).toList();
  }

  String _description(Map<String, Object?> schema) {
    return schema['description'] as String? ?? '';
  }
}
