import 'package:genui/genui.dart';
import '../schemas/genui_action_schema.dart';

typedef CatalogActionContextBuilder = Map<String, dynamic> Function();

/// Dispatches a user action event with merged catalog + component context.
void dispatchCatalogAction({
  required CatalogItemContext itemContext,
  required Object? rawAction,
  required Map<String, dynamic> actionContext,
}) {
  final action = ActionType.parse(rawAction);
  final resolvedContext = resolveContext(
    itemContext.dataContext,
    action.context ?? [],
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
  dispatchCatalogAction(
    itemContext: itemContext,
    rawAction: rawAction,
    actionContext: contextBuilder(),
  );
}
