import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../debug_logger.dart';
import 'catalog_data_normalizer.dart';

typedef CatalogDataParser<T> = T Function(Object? data);
typedef CatalogDataNormalizer = Object? Function(Object? data);
typedef TypedCatalogWidgetBuilder<T> =
    Widget Function(CatalogItemContext context, T data);

CatalogItem typedCatalogItem<T>({
  required String name,
  required Schema dataSchema,
  required List<String Function()> exampleData,
  required CatalogDataParser<T> parse,
  required TypedCatalogWidgetBuilder<T> widgetBuilder,
  CatalogDataNormalizer? normalizeData,
}) {
  return CatalogItem(
    name: name,
    dataSchema: dataSchema,
    exampleData: exampleData,
    widgetBuilder: (context) {
      try {
        final normalized = _normalizeData(context.data, normalizeData);
        final normalizedContext = _contextWithData(context, normalized);
        final data = parse(normalized);
        return widgetBuilder(normalizedContext, data);
      } catch (error, stackTrace) {
        debugLog.error(
          name,
          'Failed to build: $error\nData: ${context.data}',
          stackTrace,
        );
        return Center(child: Text('Failed to load $name'));
      }
    },
  );
}

Object _normalizeData(Object? data, CatalogDataNormalizer? normalizeData) {
  final normalized = normalizeCatalogData(data) ?? data;
  final itemNormalized = normalizeData == null
      ? normalized
      : normalizeData(normalized);
  return itemNormalized ?? const <String, Object?>{};
}

CatalogItemContext _contextWithData(CatalogItemContext context, Object data) {
  return CatalogItemContext(
    data: data,
    id: context.id,
    type: context.type,
    buildChild: context.buildChild,
    dispatchEvent: context.dispatchEvent,
    buildContext: context.buildContext,
    dataContext: context.dataContext,
    getComponent: context.getComponent,
    getCatalogItem: context.getCatalogItem,
    surfaceId: context.surfaceId,
    reportError: context.reportError,
  );
}
