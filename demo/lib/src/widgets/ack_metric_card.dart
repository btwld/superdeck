import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:flutter/material.dart';

part 'ack_metric_card.g.dart';

@AckType(name: 'AckMetricCardArgs')
final ackMetricCardArgsSchema = Ack.object({
  'label': Ack.string().notEmpty(),
  'value': Ack.string().notEmpty(),
  'caption': Ack.string().optional(),
  'tone': Ack.enumString(['blue', 'green', 'orange', 'purple']).optional(),
});

class AckMetricCard extends StatelessWidget {
  final AckMetricCardArgsType data;

  AckMetricCard(Map<String, Object?> args, {super.key})
    : data = AckMetricCardArgsType.parse(args);

  Color _toneColor(String? tone) {
    return switch (tone) {
      'green' => const Color(0xFF047857),
      'orange' => const Color(0xFFB45309),
      'purple' => const Color(0xFF7C3AED),
      _ => const Color(0xFF2563EB),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(data.tone);

    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (data.caption != null) ...[
              const SizedBox(height: 10),
              Text(
                data.caption!,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 18,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
