import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_genui/src/ai/schemas/deck_schemas.dart';
import 'package:superdeck_genui/src/ai/services/generation_progress.dart';
import 'package:superdeck_genui/src/ai/wizard_context.dart';
import 'package:superdeck_genui/src/ai/services/deck_generator_service.dart';
import 'package:superdeck_genui/src/presentation/presentation_viewmodel.dart';

void main() {
  late PresentationViewModel viewModel;

  setUp(() {
    viewModel = PresentationViewModel();
  });

  tearDown(() {
    viewModel.dispose();
  });

  // Helper to create a test callback that ignores progress
  GenerationCallback cb(
    Future<DeckGenerationResult> Function(WizardContext) fn,
  ) =>
      (context, onProgress) => fn(context);

  group('PresentationViewModel', () {
    group('initial state', () {
      test('status should be idle', () {
        expect(viewModel.status.value, GenerationStatus.idle);
      });

      test('result should be null', () {
        expect(viewModel.result.value, isNull);
      });

      test('error should be null', () {
        expect(viewModel.error.value, isNull);
      });
    });

    group('generate', () {
      test('sets status to generating immediately', () async {
        final future = viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async {
            // Delay to allow checking intermediate state
            await Future.delayed(const Duration(milliseconds: 10));
            return DeckGenerationResult.success(
              path: '/test/path',
              slideCount: 5,
            );
          }),
        );

        // Check status is generating before completion
        expect(viewModel.status.value, GenerationStatus.generating);

        await future;
      });

      test('sets status to preview on successful callback', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/test/path', slideCount: 5),
          ),
        );

        expect(viewModel.status.value, GenerationStatus.preview);
      });

      test('stores result on success', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async => DeckGenerationResult.success(
              path: '/test/path',
              slideCount: 5,
              style: DeckStyleType.parse({
                'name': 'Test Style',
                'colors': {
                  'background': '#FFFFFF',
                  'heading': '#FF0000',
                  'body': '#000000',
                },
                'fonts': {'headline': 'montserrat', 'body': 'inter'},
              }),
            ),
          ),
        );

        expect(viewModel.result.value, isNotNull);
        expect(viewModel.result.value!.success, isTrue);
        expect(viewModel.result.value!.path, '/test/path');
        expect(viewModel.result.value!.slideCount, 5);
      });

      test('sets status to error when result.success is false', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async => DeckGenerationResult.failure('API error')),
        );

        expect(viewModel.status.value, GenerationStatus.error);
      });

      test('stores error message from failed result', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async => DeckGenerationResult.failure('API error')),
        );

        expect(viewModel.error.value, 'API error');
      });

      test('sets status to error on callback exception', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async => throw Exception('Network failure')),
        );

        expect(viewModel.status.value, GenerationStatus.error);
      });

      test('stores error message from exception', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async => throw Exception('Network failure')),
        );

        expect(viewModel.error.value, contains('Network failure'));
      });

      test('clears previous result before generating', () async {
        // First generate a success
        await viewModel.generate(
          context: const WizardContext(topic: 'First'),
          callback: cb(
            (_) async => DeckGenerationResult.success(
              path: '/first/path',
              slideCount: 3,
            ),
          ),
        );
        expect(viewModel.result.value, isNotNull);

        // Start a new generation
        final future = viewModel.generate(
          context: const WizardContext(topic: 'Second'),
          callback: cb((_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return DeckGenerationResult.success(
              path: '/second/path',
              slideCount: 5,
            );
          }),
        );

        // Result should be cleared during generation
        expect(viewModel.result.value, isNull);
        await future;
      });

      test('clears previous error before generating', () async {
        // First generate an error
        await viewModel.generate(
          context: const WizardContext(topic: 'First'),
          callback: cb(
            (_) async => DeckGenerationResult.failure('First error'),
          ),
        );
        expect(viewModel.error.value, isNotNull);

        // Start a new generation
        final future = viewModel.generate(
          context: const WizardContext(topic: 'Second'),
          callback: cb((_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return DeckGenerationResult.success(path: '/path', slideCount: 5);
          }),
        );

        // Error should be cleared during generation
        expect(viewModel.error.value, isNull);
        await future;
      });

      test('passes context to callback', () async {
        WizardContext? receivedContext;

        await viewModel.generate(
          context: const WizardContext(topic: 'Test', slideCount: 10),
          callback: cb((ctx) async {
            receivedContext = ctx;
            return DeckGenerationResult.success(path: '/path', slideCount: 10);
          }),
        );

        expect(receivedContext?.topic, 'Test');
        expect(receivedContext?.slideCount, 10);
      });

      test('stores context for retry', () async {
        var callCount = 0;

        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async {
            callCount++;
            return DeckGenerationResult.success(path: '/path', slideCount: 5);
          }),
        );

        expect(callCount, 1);

        // Retry should use stored context
        await viewModel.retry();
        expect(callCount, 2);
      });
    });

    group('retry', () {
      test('does nothing when no previous context exists', () async {
        // No previous generation
        await viewModel.retry();

        expect(viewModel.status.value, GenerationStatus.idle);
        expect(viewModel.result.value, isNull);
      });

      test('regenerates with stored context', () async {
        WizardContext? lastContext;

        await viewModel.generate(
          context: const WizardContext(topic: 'Original Topic'),
          callback: cb((ctx) async {
            lastContext = ctx;
            return DeckGenerationResult.failure('Intentional failure');
          }),
        );

        expect(viewModel.status.value, GenerationStatus.error);

        // Retry should use same context
        await viewModel.retry();

        expect(lastContext?.topic, 'Original Topic');
      });

      test('uses stored callback', () async {
        var specificCallbackCalled = false;

        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async {
            specificCallbackCalled = true;
            return DeckGenerationResult.success(path: '/path', slideCount: 5);
          }),
        );

        specificCallbackCalled = false;

        await viewModel.retry();

        expect(specificCallbackCalled, isTrue);
      });

      test('can recover from error on retry', () async {
        var attemptCount = 0;

        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async {
            attemptCount++;
            if (attemptCount == 1) {
              return DeckGenerationResult.failure('First attempt failed');
            }
            return DeckGenerationResult.success(path: '/path', slideCount: 5);
          }),
        );

        expect(viewModel.status.value, GenerationStatus.error);

        await viewModel.retry();

        expect(viewModel.status.value, GenerationStatus.preview);
      });
    });

    group('preview flow', () {
      test('sets phase to generatingThumbnails on success', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        expect(viewModel.status.value, GenerationStatus.preview);
        expect(viewModel.phase.value, GenerationPhase.generatingThumbnails);
      });

      test(
        'addThumbnailPreview accumulates thumbnails with matching epoch',
        () async {
          await viewModel.generate(
            context: const WizardContext(topic: 'Test'),
            callback: cb(
              (_) async =>
                  DeckGenerationResult.success(path: '/path', slideCount: 5),
            ),
          );

          final epoch = viewModel.thumbnailEpoch;
          expect(viewModel.thumbnailPreviews.value, isEmpty);

          viewModel.addThumbnailPreview(
            2,
            Uint8List.fromList([1, 2, 3]),
            epoch: epoch,
          );
          expect(viewModel.thumbnailPreviews.value, hasLength(1));
          expect(viewModel.thumbnailPreviews.value[0].$1, 2);

          viewModel.addThumbnailPreview(
            7,
            Uint8List.fromList([4, 5, 6]),
            epoch: epoch,
          );
          expect(viewModel.thumbnailPreviews.value, hasLength(2));
          expect(viewModel.thumbnailPreviews.value[1].$1, 7);
        },
      );

      test('addThumbnailPreview ignores stale epoch', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        final staleEpoch = viewModel.thumbnailEpoch;

        // Start a new generation which increments the epoch
        await viewModel.generate(
          context: const WizardContext(topic: 'Test 2'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path2', slideCount: 3),
          ),
        );

        // Try adding with stale epoch — should be ignored
        viewModel.addThumbnailPreview(
          0,
          Uint8List.fromList([1, 2, 3]),
          epoch: staleEpoch,
        );
        expect(viewModel.thumbnailPreviews.value, isEmpty);

        // Adding with current epoch should work
        viewModel.addThumbnailPreview(
          1,
          Uint8List.fromList([4, 5, 6]),
          epoch: viewModel.thumbnailEpoch,
        );
        expect(viewModel.thumbnailPreviews.value, hasLength(1));
      });

      test(
        'finishThumbnailGeneration resets phase to idle and keeps preview when thumbnails exist',
        () async {
          await viewModel.generate(
            context: const WizardContext(topic: 'Test'),
            callback: cb(
              (_) async =>
                  DeckGenerationResult.success(path: '/path', slideCount: 5),
            ),
          );

          final epoch = viewModel.thumbnailEpoch;
          viewModel.addThumbnailPreview(
            0,
            Uint8List.fromList([1, 2, 3]),
            epoch: epoch,
          );
          expect(viewModel.phase.value, GenerationPhase.generatingThumbnails);

          viewModel.finishThumbnailGeneration(epoch: epoch);
          expect(viewModel.phase.value, GenerationPhase.idle);
          // Status remains preview until user proceeds
          expect(viewModel.status.value, GenerationStatus.preview);
        },
      );

      test(
        'finishThumbnailGeneration auto-proceeds when all thumbnails fail',
        () async {
          await viewModel.generate(
            context: const WizardContext(topic: 'Test'),
            callback: cb(
              (_) async =>
                  DeckGenerationResult.success(path: '/path', slideCount: 5),
            ),
          );

          final epoch = viewModel.thumbnailEpoch;
          expect(viewModel.thumbnailPreviews.value, isEmpty);

          viewModel.finishThumbnailGeneration(epoch: epoch);

          expect(viewModel.phase.value, GenerationPhase.idle);
          expect(viewModel.status.value, GenerationStatus.success);
        },
      );

      test('finishThumbnailGeneration ignores stale epoch', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        final staleEpoch = viewModel.thumbnailEpoch;

        // Start a new generation
        await viewModel.generate(
          context: const WizardContext(topic: 'Test 2'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path2', slideCount: 3),
          ),
        );

        // Finish with stale epoch — should be ignored
        viewModel.finishThumbnailGeneration(epoch: staleEpoch);
        expect(viewModel.phase.value, GenerationPhase.generatingThumbnails);
      });

      test('proceedToPresentation transitions to success', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        final epoch = viewModel.thumbnailEpoch;
        viewModel.addThumbnailPreview(
          0,
          Uint8List.fromList([1, 2, 3]),
          epoch: epoch,
        );
        viewModel.finishThumbnailGeneration(epoch: epoch);
        viewModel.proceedToPresentation();

        expect(viewModel.status.value, GenerationStatus.success);
        expect(viewModel.phase.value, GenerationPhase.idle);
      });

      test('thumbnails cleared on new generation', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        viewModel.addThumbnailPreview(
          0,
          Uint8List.fromList([1, 2, 3]),
          epoch: viewModel.thumbnailEpoch,
        );
        expect(viewModel.thumbnailPreviews.value, hasLength(1));

        // Start new generation - thumbnails should be cleared
        await viewModel.generate(
          context: const WizardContext(topic: 'Test 2'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path2', slideCount: 3),
          ),
        );

        expect(viewModel.thumbnailPreviews.value, isEmpty);
      });

      test('thumbnailEpoch increments on each generation', () async {
        final initialEpoch = viewModel.thumbnailEpoch;

        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        expect(viewModel.thumbnailEpoch, greaterThan(initialEpoch));

        final secondEpoch = viewModel.thumbnailEpoch;

        await viewModel.generate(
          context: const WizardContext(topic: 'Test 2'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path2', slideCount: 3),
          ),
        );

        expect(viewModel.thumbnailEpoch, greaterThan(secondEpoch));
      });
    });

    group('reset', () {
      test('sets status to idle', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );
        expect(viewModel.status.value, GenerationStatus.preview);

        viewModel.reset();

        expect(viewModel.status.value, GenerationStatus.idle);
      });

      test('clears result', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );
        expect(viewModel.result.value, isNotNull);

        viewModel.reset();

        expect(viewModel.result.value, isNull);
      });

      test('clears error', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async => DeckGenerationResult.failure('Error')),
        );
        expect(viewModel.error.value, isNotNull);

        viewModel.reset();

        expect(viewModel.error.value, isNull);
      });

      test('clears thumbnails and increments epoch', () async {
        await viewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );

        final epochBeforeReset = viewModel.thumbnailEpoch;
        viewModel.addThumbnailPreview(
          0,
          Uint8List.fromList([1, 2, 3]),
          epoch: epochBeforeReset,
        );
        expect(viewModel.thumbnailPreviews.value, hasLength(1));

        viewModel.reset();

        expect(viewModel.thumbnailPreviews.value, isEmpty);
        expect(viewModel.thumbnailEpoch, greaterThan(epochBeforeReset));
      });

      test('from idle keeps state clean', () {
        viewModel.reset();
        expect(viewModel.status.value, GenerationStatus.idle);
        expect(viewModel.result.value, isNull);
        expect(viewModel.error.value, isNull);
      });
    });

    group('dispose', () {
      test('is idempotent after generation', () async {
        final localViewModel = PresentationViewModel();
        await localViewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb(
            (_) async =>
                DeckGenerationResult.success(path: '/path', slideCount: 5),
          ),
        );
        expect(localViewModel.status.value, GenerationStatus.preview);

        localViewModel.dispose();
        localViewModel.dispose();
      });

      test('is idempotent after error path', () async {
        final localViewModel = PresentationViewModel();
        await localViewModel.generate(
          context: const WizardContext(topic: 'Test'),
          callback: cb((_) async => DeckGenerationResult.failure('Error')),
        );
        expect(localViewModel.status.value, GenerationStatus.error);

        localViewModel.dispose();
        localViewModel.dispose();
      });
    });

    group('GenerationStatus enum', () {
      test('has all expected values', () {
        expect(
          GenerationStatus.values,
          containsAll([
            GenerationStatus.idle,
            GenerationStatus.generating,
            GenerationStatus.preview,
            GenerationStatus.success,
            GenerationStatus.error,
          ]),
        );
      });
    });
  });
}
