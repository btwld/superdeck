// Import all block classes
import 'base_block.dart';
import 'dartpad_block.dart';
import 'image_block.dart';
import 'markdown_block.dart';
import 'section_block.dart';
import 'widget_block.dart';

/// Initializes all block mappers to ensure proper registration
/// Call this function early in the app initialization
void initializeBlockMappers() {
  // Initialize all mapper classes
  // This ensures they're properly registered with the mapper container
  BaseBlockMapper.ensureInitialized();

  // Initialize all concrete block types
  // The order is important for correct registration
  MarkdownBlockMapper.ensureInitialized();
  SectionBlockMapper.ensureInitialized();
  ImageBlockMapper.ensureInitialized();
  WidgetBlockMapper.ensureInitialized();
  DartPadBlockMapper.ensureInitialized();
}
