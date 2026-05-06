import 'dart:convert';

const _encoder = JsonEncoder.withIndent('  ');

String prettyJson(dynamic json) => _encoder.convert(json);
