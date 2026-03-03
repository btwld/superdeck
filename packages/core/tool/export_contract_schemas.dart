import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');
  final schemaDir = Directory(p.join(Directory.current.path, 'schema'));

  final artifacts = <String, Map<String, Object?>>{
    'superdeck.deck.schema.json': _decorateSchema(
      id: 'https://superdeck.dev/schema/superdeck.deck.schema.json',
      title: 'SuperDeck Deck Contract',
      schema: Deck.schema.toJsonSchema(),
    ),
  };

  if (!checkOnly) {
    await schemaDir.create(recursive: true);
  }

  var hasDrift = false;

  for (final entry in artifacts.entries) {
    final file = File(p.join(schemaDir.path, entry.key));
    final nextContent = _encodeJson(entry.value);

    if (!await file.exists()) {
      if (checkOnly) {
        stderr.writeln('Missing schema artifact: ${file.path}');
        hasDrift = true;
      } else {
        await file.create(recursive: true);
        await file.writeAsString(nextContent);
        stdout.writeln('Wrote ${file.path}');
      }
      continue;
    }

    final currentContent = await file.readAsString();
    if (currentContent == nextContent) {
      stdout.writeln('Up to date: ${file.path}');
      continue;
    }

    if (checkOnly) {
      stderr.writeln('Schema artifact drift detected: ${file.path}');
      hasDrift = true;
    } else {
      await file.writeAsString(nextContent);
      stdout.writeln('Updated ${file.path}');
    }
  }

  if (checkOnly && hasDrift) {
    stderr.writeln(
      'Contract schema artifacts are stale. '
      'Run: fvm dart run tool/export_contract_schemas.dart',
    );
    exitCode = 1;
  }
}

Map<String, Object?> _decorateSchema({
  required String id,
  required String title,
  required Map<String, Object?> schema,
}) {
  return <String, Object?>{
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    r'$id': id,
    'title': title,
    ...schema,
  };
}

String _encodeJson(Map<String, Object?> schema) {
  final canonical = _canonicalize(schema) as Map<String, Object?>;
  return '${const JsonEncoder.withIndent('  ').convert(canonical)}\n';
}

Object? _canonicalize(Object? value) {
  return switch (value) {
    Map map => <String, Object?>{
      for (final key in map.keys.map((key) => key as String).toList()..sort())
        key: _canonicalize(map[key]),
    },
    List list => list.map(_canonicalize).toList(),
    _ => value,
  };
}
