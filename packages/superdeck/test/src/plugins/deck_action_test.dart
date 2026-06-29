import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';

void main() {
  group('DeckAction', () {
    test('stores runtime deck action metadata', () {
      final action = DeckAction(
        id: 'test.action',
        label: 'Test Action',
        icon: const IconData(0xe000, fontFamily: 'MaterialIcons'),
        onPressed: (_, _) {},
      );

      expect(action.id, 'test.action');
      expect(action.label, 'Test Action');
      expect(action.icon.codePoint, 0xe000);
    });

    test('rejects empty ids and labels', () {
      expect(
        () => DeckAction(
          id: '',
          label: 'Test Action',
          icon: const IconData(0xe000, fontFamily: 'MaterialIcons'),
          onPressed: (_, _) {},
        ),
        throwsArgumentError,
      );
      expect(
        () => DeckAction(
          id: 'test.action',
          label: '  ',
          icon: const IconData(0xe000, fontFamily: 'MaterialIcons'),
          onPressed: (_, _) {},
        ),
        throwsArgumentError,
      );
    });
  });
}
