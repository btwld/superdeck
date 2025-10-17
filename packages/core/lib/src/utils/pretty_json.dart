import 'dart:convert';

String prettyJson(dynamic json) {
  var spaces = ' ' * 2;
  var encoder = JsonEncoder.withIndent(spaces);

  return encoder.convert(json);
}
