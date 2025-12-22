import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_example/main.dart';

void main() {
  testWidgets('TwitterWidget renders username', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TwitterWidget(username: 'alice', tweetId: '123'),
      ),
    );

    expect(find.text('Twitter: alice'), findsOneWidget);
  });
}
