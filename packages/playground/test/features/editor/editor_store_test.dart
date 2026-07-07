import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/editor/domain/stores/editor_store.dart';

void main() {
  EditorStore newStore() {
    final store = EditorStore();
    addTearDown(store.dispose);
    return store;
  }

  group('activeSlideIndex', () {
    test('defaults to 0', () {
      expect(newStore().activeSlideIndex, 0);
    });

    test('notifies on change and no-ops otherwise', () {
      final store = newStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.activeSlideIndex = 2;
      store.activeSlideIndex = 2;

      expect(store.activeSlideIndex, 2);
      expect(notifications, 1);
    });
  });

  group('previewSidebarWidth', () {
    test('defaults to the minimum width', () {
      expect(newStore().previewSidebarWidth,
          EditorStore.minPreviewSidebarWidth);
    });

    test('clamps below the minimum', () {
      final store = newStore();
      store.previewSidebarWidth = 0;
      expect(store.previewSidebarWidth, EditorStore.minPreviewSidebarWidth);
    });

    test('clamps above the maximum', () {
      final store = newStore();
      store.previewSidebarWidth = 10000;
      expect(store.previewSidebarWidth, EditorStore.maxPreviewSidebarWidth);
    });

    test('accepts an in-range value and notifies once', () {
      final store = newStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.previewSidebarWidth = 300;

      expect(store.previewSidebarWidth, 300);
      expect(notifications, 1);
    });

    test('does not notify when the clamped value is unchanged', () {
      final store = newStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      // Already at the minimum; clamping a smaller value yields no change.
      store.previewSidebarWidth = -5;

      expect(notifications, 0);
    });
  });

  group('customizationSidebarWidth', () {
    test('defaults to the maximum width', () {
      expect(newStore().customizationSidebarWidth,
          EditorStore.maxCustomizationSidebarWidth);
    });

    test('clamps below the minimum', () {
      final store = newStore();
      store.customizationSidebarWidth = 0;
      expect(store.customizationSidebarWidth,
          EditorStore.minCustomizationSidebarWidth);
    });

    test('clamps above the maximum', () {
      final store = newStore();
      store.customizationSidebarWidth = 10000;
      expect(store.customizationSidebarWidth,
          EditorStore.maxCustomizationSidebarWidth);
    });
  });

  group('sidebar visibility', () {
    test('both sidebars are visible by default', () {
      final store = newStore();
      expect(store.showPreviewSidebar, isTrue);
      expect(store.showCustomizationSidebar, isTrue);
    });

    test('togglePreviewSidebar updates state and notifies', () {
      final store = newStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.togglePreviewSidebar(false);

      expect(store.showPreviewSidebar, isFalse);
      expect(notifications, 1);
    });

    test('toggleCustomizationSidebar updates state and notifies', () {
      final store = newStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.toggleCustomizationSidebar(false);

      expect(store.showCustomizationSidebar, isFalse);
      expect(notifications, 1);
    });
  });
}
