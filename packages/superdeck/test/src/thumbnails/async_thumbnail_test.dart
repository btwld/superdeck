import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/thumbnails/async_thumbnail.dart';

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(key: key),
    ),
  );
  return key.currentContext!;
}

void main() {
  group('AsyncThumbnail', () {
    group('initialization', () {
      test('initializes with idle status', () {
        final thumbnail = AsyncThumbnail(
          thumbnailKey: 'thumbnail_idle.png',
          generator: (context, {required force}) async {
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
          thumbnailKey: 'thumbnail_empty.png',
          generator: (context, {required force}) async {
            throw UnimplementedError('Should not be called');
          },
        );

        expect(thumbnail.imageProvider, isNull);

        thumbnail.dispose();
      });
    });

    group('disposal', () {
      test('can be disposed without loading', () {
        final thumbnail = AsyncThumbnail(
          thumbnailKey: 'thumbnail_dispose.png',
          generator: (context, {required force}) async {
            throw UnimplementedError('Should not be called');
          },
        );
        thumbnail.dispose();
      });

      test('double dispose does not throw', () {
        final thumbnail = AsyncThumbnail(
          thumbnailKey: 'thumbnail_double_dispose.png',
          generator: (context, {required force}) async {
            throw UnimplementedError('Should not be called');
          },
        );

        thumbnail.dispose();
        thumbnail.dispose();
      });
    });

    group('load', () {
      testWidgets('queues force reload while generation is in progress', (
        tester,
      ) async {
        final context = await _pumpContext(tester);
        final firstGeneration = Completer<Uri?>();
        final secondGeneration = Completer<Uri?>();
        final forceValues = <bool>[];
        var calls = 0;

        final thumbnail = AsyncThumbnail(
          thumbnailKey: 'thumbnail_queue_force.png',
          generator: (context, {required force}) {
            forceValues.add(force);
            calls += 1;

            return switch (calls) {
              1 => firstGeneration.future,
              2 => secondGeneration.future,
              _ => Future.value(Uri.parse('file:///tmp/unexpected.png')),
            };
          },
        );

        final firstLoad = thumbnail.load(context);
        expect(calls, 1);
        expect(forceValues, equals([false]));
        expect(thumbnail.status.value, equals(AsyncFileStatus.loading));

        await thumbnail.load(context, true);
        expect(calls, 1);

        firstGeneration.complete(Uri.parse('file:///tmp/first.png'));
        await firstLoad;

        expect(calls, 2);
        expect(forceValues, equals([false, true]));
        expect(thumbnail.status.value, equals(AsyncFileStatus.loading));

        secondGeneration.complete(Uri.parse('file:///tmp/second.png'));
        await tester.pump();

        expect(thumbnail.status.value, equals(AsyncFileStatus.done));
        expect(thumbnail.error.value, isNull);
        expect(thumbnail.imageProvider, isNotNull);

        thumbnail.dispose();
      });
    });
  });
}
