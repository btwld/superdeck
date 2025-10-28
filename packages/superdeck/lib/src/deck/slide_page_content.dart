import 'package:flutter/material.dart';

import '../rendering/slides/slide_screen.dart';
import 'deck_controller.dart';
import 'deck_provider.dart';

/// Widget for rendering slide page content
///
/// Handles loading states, errors, and syncing route index with navigation controller.
/// Separated from NavigationController to avoid tight coupling.
class SlidePageContent extends StatelessWidget {
  final int index;

  const SlidePageContent({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final deckController = DeckController.of(context);
    final navigationController = NavigationProvider.of(context);

    // Sync route index to navigation controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationController.updateCurrentIndex(index);
    });

    // Use ListenableBuilder to react to both controllers
    return ListenableBuilder(
      listenable: Listenable.merge([deckController, navigationController]),
      builder: (context, child) {
        // Access deck controller state
        final isLoading = deckController.isLoading;
        final hasError = deckController.hasError;
        final slides = deckController.slides;

        // Render appropriate state
        if (hasError) {
          return _ErrorScreen(
            error: deckController.error,
            onRetry: deckController.repository.loadDeckStream,
          );
        }

        if (isLoading) {
          return const _LoadingScreen();
        }

        if (slides.isEmpty) {
          return const _NoSlidesScreen();
        }

        final safeIndex = index.clamp(0, slides.length - 1);
        return Semantics(
          label: 'Slide ${safeIndex + 1}',
          container: true,
          child: SlideScreen(slides[safeIndex]),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading presentation...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading presentation: $error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NoSlidesScreen extends StatelessWidget {
  const _NoSlidesScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.slideshow_outlined, size: 72, color: Colors.blueGrey),
              SizedBox(height: 24),
              Text(
                'No slides available',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Add slides to your deck (slides.md) and rebuild to start presenting.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
