import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/export/async_thumbnail.dart';

void main() {
  group('AsyncThumbnail', () {
    test('initializes with idle status', () {
      final thumbnail = AsyncThumbnail(
        generator: (context, force) async {
          throw UnimplementedError('Should not be called');
        },
      );

      expect(thumbnail.status.value, equals(AsyncFileStatus.idle));
      expect(thumbnail.error.value, isNull);
      expect(thumbnail.imageProvider, isNull);

      thumbnail.dispose();
    });

    test('imageProvider returns null when no file loaded', () {
      final thumbnail = AsyncThumbnail(
        generator: (context, force) async {
          throw UnimplementedError('Should not be called');
        },
      );

      expect(thumbnail.imageProvider, isNull);

      thumbnail.dispose();
    });

    testWidgets('shows placeholder when thumbnail file is missing', (
      tester,
    ) async {
      final thumbnail = AsyncThumbnail(generator: (_, __) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                SizedBox.expand(child: thumbnail.build(context)),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Preview unavailable'), findsOneWidget);
      expect(thumbnail.status.value, AsyncFileStatus.done);

      thumbnail.dispose();
    });

    testWidgets('does not expose retry action on load error', (tester) async {
      var generatorCalls = 0;
      final thumbnail = AsyncThumbnail(
        generator: (_, __) async {
          generatorCalls++;
          throw FileSystemException('read error');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                SizedBox.expand(child: thumbnail.build(context)),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Preview unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(generatorCalls, 1);

      thumbnail.dispose();
    });

    test('double dispose does not throw', () {
      final thumbnail = AsyncThumbnail(
        generator: (context, force) async {
          throw UnimplementedError('Should not be called');
        },
      );

      thumbnail.dispose();
      thumbnail.dispose();
    });
  });
}
