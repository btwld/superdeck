import 'package:superdeck/superdeck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('superdeck public api', () {
    test('exports the supported app surface', () {
      expect(SuperDeckApp, isNotNull);
      expect(DeckController, isNotNull);
      expect(BundledDeckLoader, isNotNull);
      expect(FileDeckLoader, isNotNull);
      expect(SlideConfiguration, isNotNull);
    });
  });
}
