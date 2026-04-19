import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SuperDeckApp.initialize', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('propagates dependency initialization errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async => null);

      await expectLater(
        SuperDeckApp.initialize(),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
