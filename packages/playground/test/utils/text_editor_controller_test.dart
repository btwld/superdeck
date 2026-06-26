import 'package:flutter_test/flutter_test.dart';
import 'package:playground/utils/text_editor_controller.dart';

void main() {
  group('TextEditorController', () {
    test('loadMarkdown creates a one-shot pending handoff', () {
      final controller = TextEditorController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.loadMarkdown('deck');

      expect(notifications, 1);
      expect(controller.latestMarkdown, 'deck');
      expect(controller.takePendingMarkdown(), 'deck');
      expect(controller.takePendingMarkdown(), isNull);
    });

    test('staged next-mount handoff does not notify mounted listeners', () {
      final controller = TextEditorController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.stageMarkdownForNextEditorMount('abort-deck');

      expect(notifications, 0);
      expect(controller.latestMarkdown, 'abort-deck');
      expect(controller.takeStagedMarkdownForNextEditorMount(), 'abort-deck');
      expect(controller.takeStagedMarkdownForNextEditorMount(), isNull);
    });

    test('outbound write suspension is explicit', () {
      final controller = TextEditorController();
      addTearDown(controller.dispose);

      expect(controller.outboundWritesSuspended, isFalse);

      controller.suspendOutboundWritesForAiEntry();
      expect(controller.outboundWritesSuspended, isTrue);

      controller.resumeOutboundWritesForEditorMount();
      expect(controller.outboundWritesSuspended, isFalse);
    });
  });
}
