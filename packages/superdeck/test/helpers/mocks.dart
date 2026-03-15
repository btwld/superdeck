import 'package:mocktail/mocktail.dart';
import 'package:superdeck/src/deck/navigation_service.dart';
import 'package:superdeck/src/export/slide_capture_service.dart';
import 'package:superdeck/src/export/thumbnail_service.dart';

/// Mock for NavigationService - used for testing DeckController navigation
class MockNavigationService extends Mock implements NavigationService {}

/// Mock for ThumbnailService - used for testing DeckController thumbnails
class MockThumbnailService extends Mock implements ThumbnailService {}

/// Mock for SlideCaptureService - used for testing ThumbnailService
class MockSlideCaptureService extends Mock implements SlideCaptureService {}
