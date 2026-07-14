import 'package:flutter/material.dart';
import 'package:superdeck/superdeck.dart';

final showcaseWidgets = <String, WidgetFactory>{
  'showcaseMetric': ShowcaseMetric.new,
};

class ShowcaseMetric extends StatelessWidget {
  ShowcaseMetric(Map<String, Object?> args, {super.key})
    : value = args['value'] as String? ?? '—',
      label = args['label'] as String? ?? '',
      detail = args['detail'] as String? ?? '',
      accent = _parseColor(args['accent'], const Color(0xFFFF8A65));

  final String value;
  final String label;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFF8F4F2),
                  fontSize: 58,
                  height: 0.92,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFF0ECEF),
                  fontSize: 19,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF99959F),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _parseColor(Object? value, Color fallback) {
  if (value is! String) return fallback;
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) return fallback;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}
