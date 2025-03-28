import 'dart:math' as math;

import 'package:flutter/widgets.dart';

({
  String? tag,
  String content,
}) getTagAndContent(String text) {
  text = text.trim();
  final regExp = RegExp(r'{\.(.*?)}');

  final match = regExp.firstMatch(text);

  final tag = match?.group(1);

  String content = text.replaceAll(regExp, '').trim();
  // TODO: Remove this for code element after
  content = content.replaceAll('```', '');

  return (
    tag: tag,
    content: content,
  );
}

String lerpString(String start, String end, double t) {
  // Clamp t between 0 and 1
  t = t.clamp(0.0, 1.0);

  final commonPrefixLen = start.commonPrefixLength(end);
  final startSuffix = start.substring(commonPrefixLen);
  final endSuffix = end.substring(commonPrefixLen);

  final result = StringBuffer();
  result.write(end.substring(0, commonPrefixLen));

  if (t <= 0.5) {
    final progress = t / 0.5;
    final startLength = startSuffix.length;
    final numCharsToShow = ((1 - progress) * startLength).round();
    if (numCharsToShow > 0) {
      result.write(startSuffix.substring(0, numCharsToShow));
    }
  } else {
    final progress = (t - 0.5) / 0.5;
    final endLength = endSuffix.length;
    final numCharsToShow = (progress * endLength).round();
    if (numCharsToShow > 0) {
      result.write(endSuffix.substring(0, numCharsToShow));
    }
  }

  return result.toString();
}

extension on String {
  int commonPrefixLength(String other) {
    final len = math.min(length, other.length);
    for (int i = 0; i < len; i++) {
      if (this[i] != other[i]) {
        return i;
      }
    }
    return len;
  }
}

List<TextSpan> lerpTextSpans(
  List<TextSpan> start,
  List<TextSpan> end,
  double t,
) {
  final maxLines = math.max(start.length, end.length);
  List<TextSpan> interpolatedSpans = [];

  for (int i = 0; i < maxLines; i++) {
    final startSpan = i < start.length ? start[i] : const TextSpan(text: '');
    final endSpan = i < end.length ? end[i] : const TextSpan(text: '');

    if (startSpan.text == null && endSpan.text == null) {
      // if chilrens are not null recursive
      if (startSpan.children != null && endSpan.children != null) {
        if (startSpan.children!.isEmpty && endSpan.children!.isEmpty) {
          continue;
        }
        final children = lerpTextSpans(
          startSpan.children! as List<TextSpan>,
          endSpan.children! as List<TextSpan>,
          t,
        );
        final interpolatedSpan = TextSpan(
          children: children,
          style: TextStyle.lerp(startSpan.style, endSpan.style, t),
        );
        interpolatedSpans.add(interpolatedSpan);
        continue;
      }
    }

    final interpolatedText =
        lerpString(startSpan.text ?? '', endSpan.text ?? '', t);
    final interpolatedStyle = TextStyle.lerp(startSpan.style, endSpan.style, t);

    final interpolatedSpan =
        TextSpan(text: interpolatedText, style: interpolatedStyle);

    interpolatedSpans.add(interpolatedSpan);
  }

  return interpolatedSpans;
}
