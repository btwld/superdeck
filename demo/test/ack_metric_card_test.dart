import 'package:ack/ack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_example/src/widgets/ack_metric_card.dart';

void main() {
  testWidgets('AckMetricCard renders generated typed args', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AckMetricCard({
          'label': 'Activation',
          'value': '72%',
          'caption': 'Parsed through Ack-generated typed getters',
          'tone': 'green',
        }),
      ),
    );

    expect(find.text('ACTIVATION'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(
      find.text('Parsed through Ack-generated typed getters'),
      findsOneWidget,
    );
  });

  test('AckMetricCard validates required args', () {
    expect(() => AckMetricCard({'value': '72%'}), throwsA(isA<AckException>()));
  });
}
