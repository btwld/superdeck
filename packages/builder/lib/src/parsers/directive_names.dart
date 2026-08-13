import 'package:superdeck_core/superdeck_core.dart';

/// Legacy `@column` tag. Parse rejects it; serialize must not emit it as
/// widget shorthand or reparse would throw.
const deprecatedColumnDirective = 'column';

/// Authoring tags that are not widget shorthand.
///
/// `section`, `block`, and `widget` are the structural tags (model
/// discriminators). [deprecatedColumnDirective] is a rejected `@block` alias.
/// Parse and serialize both use this set.
const reservedDirectiveNames = {
  SectionBlock.key,
  ContentBlock.key,
  WidgetBlock.key,
  deprecatedColumnDirective,
};
