import 'package:genui/genui.dart';

import 'catalog.dart';

/// Minimal catalog for the Remix component builder experience.
final remixCatalog = Catalog([
  withCatalogErrorHandling(remixComponentPreview),
], catalogId: 'com.superdeck.ai.remix');
