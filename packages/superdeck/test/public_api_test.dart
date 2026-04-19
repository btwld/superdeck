import 'package:superdeck/superdeck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('superdeck public api', () {
    test('exports the supported app surface', () {
      expect(SuperDeckApp, isNotNull);
      expect(SlideConfiguration, isNotNull);
    });
  });
}
