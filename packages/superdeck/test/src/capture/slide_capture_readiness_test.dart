import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/capture/slide_capture_readiness.dart';

/// Registers one dependency with the readiness scope above it.
class _Dependency extends StatefulWidget {
  const _Dependency({
    super.key,
    required this.label,
    required this.onHandle,
  });

  final String label;
  final void Function(SlideCaptureReadinessHandle handle) onHandle;

  @override
  State<_Dependency> createState() => _DependencyState();
}

class _DependencyState extends State<_Dependency> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onHandle(SlideCaptureReadiness.track(context, label: widget.label));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  Future<SlideCaptureReadinessHandle> pumpDependency(
    WidgetTester tester,
    SlideCaptureReadiness readiness, {
    String label = 'image:hero.png',
    Key? key,
  }) async {
    late SlideCaptureReadinessHandle handle;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: readiness.bind(
          _Dependency(
            key: key,
            label: label,
            onHandle: (tracked) => handle = tracked,
          ),
        ),
      ),
    );

    return handle;
  }

  group('SlideCaptureReadiness', () {
    testWidgets('a tracked dependency holds the scope until it completes', (
      tester,
    ) async {
      final readiness = SlideCaptureReadiness();
      final handle = await pumpDependency(tester, readiness);

      expect(readiness.isReady, isFalse);
      expect(readiness.pendingCount, 1);
      expect(readiness.pendingLabels, ['image:hero.png']);

      handle.complete();

      expect(readiness.isReady, isTrue);
      expect(readiness.failures, isEmpty);
    });

    testWidgets('a failed dependency ends the wait and names itself', (
      tester,
    ) async {
      final readiness = SlideCaptureReadiness();
      final handle = await pumpDependency(tester, readiness);

      handle.fail('404');

      expect(readiness.isReady, isTrue);
      expect(readiness.failures, hasLength(1));
      expect(readiness.failures.single.label, 'image:hero.png');
      expect(readiness.failures.single.reason, '404');
    });

    testWidgets('the first outcome is the one that counts', (tester) async {
      final readiness = SlideCaptureReadiness();
      final handle = await pumpDependency(tester, readiness);

      handle.complete();
      handle.fail('too late');

      expect(readiness.isReady, isTrue);
      expect(readiness.failures, isEmpty);
      expect(handle.isCompleted, isTrue);
    });

    testWidgets('a failure is kept after a later dependency succeeds', (
      tester,
    ) async {
      final readiness = SlideCaptureReadiness();
      final failed = await pumpDependency(
        tester,
        readiness,
        label: 'image:a',
        key: const ValueKey('first'),
      );
      failed.fail('404');
      // The dependency is rebuilt from scratch, the way a remounted page is.
      final reloaded = await pumpDependency(
        tester,
        readiness,
        label: 'image:a',
        key: const ValueKey('reloaded'),
      );
      reloaded.complete();

      expect(readiness.isReady, isTrue);
      expect(readiness.failures, hasLength(1));
    });

    testWidgets('outside a scope a handle is already complete', (tester) async {
      late SlideCaptureReadinessHandle handle;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Dependency(
            label: 'image:hero.png',
            onHandle: (tracked) => handle = tracked,
          ),
        ),
      );

      expect(handle.isCompleted, isTrue);
      handle.fail('ignored');
      expect(handle.isCompleted, isTrue);
    });
  });
}
