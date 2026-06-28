import 'dart:async';

import 'package:genui/genui.dart';
import '../schemas/genui_action_schema.dart';

typedef CatalogActionContextBuilder = Map<String, dynamic> Function();

/// Dispatches a user action event with merged catalog + component context.
Future<void> dispatchCatalogAction({
  required CatalogItemContext itemContext,
  required Object? rawAction,
  required Map<String, dynamic> actionContext,
}) async {
  final action = ActionType.parse(rawAction);
  final resolvedContext = await resolveContext(
    itemContext.dataContext,
    actionContextDefinitionFromAction(action),
  );
  resolvedContext.addAll(actionContext);

  itemContext.dispatchEvent(
    UserActionEvent(
      name: action.name,
      sourceComponentId: itemContext.id,
      context: resolvedContext,
    ),
  );
}

/// Dispatches a catalog action only when [canSubmit] is true.
///
/// This centralizes the common submit guard + context builder pattern used by
/// multiple catalog question widgets.
void submitCatalogActionIfValid({
  required bool canSubmit,
  required CatalogItemContext itemContext,
  required Object? rawAction,
  required CatalogActionContextBuilder contextBuilder,
}) {
  if (!canSubmit) return;
  unawaited(
    dispatchCatalogAction(
      itemContext: itemContext,
      rawAction: rawAction,
      actionContext: contextBuilder(),
    ),
  );
}

JsonMap actionContextDefinitionFromAction(ActionType action) {
  final entries = action.context;
  if (entries == null) return {};

  return {for (final entry in entries) entry.key: _contextValue(entry.value)};
}

Object? _contextValue(ActionContextValueType value) {
  if (value.path case final path?) {
    return {'path': path};
  }
  if (value.literalString case final literal?) return literal;
  if (value.literalNumber case final literal?) return literal;
  if (value.literalBoolean case final literal?) return literal;
  return null;
}
