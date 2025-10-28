import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/widget_definition.dart';
import '../rendering/blocks/block_provider.dart';
import '../ui/widgets/webview_wrapper.dart';

/// Strongly-typed data transfer object for DartPad widget.
class DartPadDto {
  /// DartPad snippet ID.
  final String id;

  /// Theme (light or dark).
  final DartPadTheme? theme;

  /// Whether to embed.
  final bool embed;

  /// Whether to auto-run.
  final bool run;

  const DartPadDto({
    required this.id,
    this.theme,
    this.embed = true,
    this.run = true,
  });

  /// Schema for validating DartPad arguments.
  static final schema = Ack.object({
    'id': Ack.string().notEmpty(),
    'theme': DartPadTheme.schema.nullable().optional(),
    'embed': Ack.boolean().nullable().optional(),
    'run': Ack.boolean().nullable().optional(),
  });

  /// Parses and validates raw map into typed DartPadDto.
  static DartPadDto parse(Map<String, Object?> map) {
    schema.parse(map); // Validate first

    // Parse optional theme
    final themeStr = map['theme'] as String?;
    final theme = themeStr != null ? DartPadTheme.fromJson(themeStr) : null;

    return DartPadDto(
      id: map['id'] as String,
      theme: theme,
      embed: map['embed'] as bool? ?? true,
      run: map['run'] as bool? ?? true,
    );
  }

  /// Builds the DartPad URL from these arguments.
  String toUrl() {
    final params = [
      'id=$id',
      if (theme != null) 'theme=${theme!.name}',
      'embed=$embed',
      'run=$run',
    ];
    return 'https://dartpad.dev/?${params.join('&')}';
  }
}

/// Built-in widget for embedding DartPad code editors in slides.
///
/// Usage in markdown:
/// ```markdown
/// @dartpad {
///   id: abc123
///   theme: dark
///   embed: true
///   run: false
/// }
/// ```
///
/// Parameters:
/// - `id` (required): DartPad snippet ID
/// - `theme` (optional): Theme name (light, dark) - default: light
/// - `embed` (optional): Whether to embed - default: true
/// - `run` (optional): Whether to auto-run - default: true
class DartPadWidget extends WidgetDefinition<DartPadDto> {
  const DartPadWidget();

  @override
  DartPadDto parse(Map<String, Object?> args) => DartPadDto.parse(args);

  @override
  Widget build(BuildContext context, DartPadDto args) {
    // Access block data for sizing
    final data = BlockData.of(context);

    return WebViewWrapper(size: data.size, url: args.toUrl());
  }
}
