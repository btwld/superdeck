// ==============================
// FILE: mermaid_theme.dart
// ==============================

import 'color_utils.dart';

/// Simple 5-swatch theme that expands to Mermaid's themeVariables (v11).
///
/// New: [canvasOnDarkSlide] + optional [canvasTextOverride] control how
/// "canvas" text (titles/edge labels outside nodes) is colored for
/// transparent PNGs placed on light *or* dark slides.
class MermaidTheme {
  /// Background color behind nodes when the diagram is rendered on an opaque BG.
  final String background; // e.g. '#0b0f14'

  /// Accent color for nodes/borders/highlights.
  final String primary; // e.g. '#0ea5e9'

  /// Text color used inside nodes (on colored fills).
  final String text; // e.g. '#e2e8f0'

  /// Dark-mode toggle influences derived colors.
  final bool darkMode;

  /// Whether the resulting PNG will sit on a dark slide.
  final bool canvasOnDarkSlide;

  /// Optional explicit canvas text color (overrides the heuristic).
  final String? canvasTextOverride;

  const MermaidTheme({
    required this.background,
    required this.primary,
    required this.text,
    this.darkMode = true,
    this.canvasOnDarkSlide = false,
    this.canvasTextOverride,
  });

  /// Dark theme preset (default)
  static const dark = MermaidTheme(
    background: '#0b0f14',
    primary: '#0ea5e9',
    text: '#e2e8f0',
    darkMode: true,
    canvasOnDarkSlide: false,
  );

  /// Light theme preset
  static const light = MermaidTheme(
    background: '#ffffff',
    primary: '#0066FF',
    text: '#1a1a1a',
    darkMode: false,
    canvasOnDarkSlide: false,
  );

  MermaidTheme copyWith({
    String? background,
    String? primary,
    String? text,
    bool? darkMode,
    bool? canvasOnDarkSlide,
    String? canvasTextOverride,
  }) => MermaidTheme(
    background: background ?? this.background,
    primary: primary ?? this.primary,
    text: text ?? this.text,
    darkMode: darkMode ?? this.darkMode,
    canvasOnDarkSlide: canvasOnDarkSlide ?? this.canvasOnDarkSlide,
    canvasTextOverride: canvasTextOverride ?? this.canvasTextOverride,
  );

  /// Expand the theme into Mermaid-compliant themeVariables.
  Map<String, dynamic> toThemeVariables() {
    final surface = _deriveSurface(background, darkMode);
    final primaryBorder = ColorUtils.darken(primary, 0.2);

    // Derive secondary and tertiary colors
    final secondary = ColorUtils.lighten(primary, 0.15);
    final secondaryBorder = ColorUtils.darken(secondary, 0.15);
    final tertiary = ColorUtils.lighten(background, darkMode ? 0.20 : 0.05);
    final tertiaryBorder = ColorUtils.lighten(tertiary, darkMode ? 0.15 : 0.10);

    // Canvas/label text rendered on transparent PNGs over slides.
    final canvasText =
        canvasTextOverride ??
        (canvasOnDarkSlide
            ? '#f5f5f5' /* light ink */
            : '#1a1a1a' /* dark ink */ );

    // Git/categorical color palette (used by multiple diagram types)
    final gitColors = [
      primary,
      ColorUtils.lighten(primary, 0.2),
      ColorUtils.darken(primary, 0.2),
      ColorUtils.lighten(primary, 0.4),
      ColorUtils.darken(primary, 0.4),
      ColorUtils.lighten(primary, 0.6),
      ColorUtils.darken(primary, 0.6),
      ColorUtils.lighten(primary, 0.8),
    ];

    final vars = <String, dynamic>{
      // Core global variables (v11.12.0)
      'darkMode': darkMode,
      'background': background,
      'fontFamily': 'Inter, ui-sans-serif, system-ui, sans-serif',
      'fontSize': '18px',

      // Primary colors
      'primaryColor': primary,
      'primaryTextColor': ColorUtils.contrastColor(
        primary,
        light: '#ffffff',
        dark: '#000000',
      ),
      'primaryBorderColor': primaryBorder,

      // Secondary colors
      'secondaryColor': secondary,
      'secondaryTextColor': ColorUtils.contrastColor(
        secondary,
        light: '#ffffff',
        dark: '#000000',
      ),
      'secondaryBorderColor': secondaryBorder,

      // Tertiary colors
      'tertiaryColor': tertiary,
      'tertiaryTextColor': text,
      'tertiaryBorderColor': tertiaryBorder,

      // Notes
      'noteBkgColor': ColorUtils.lighten(primary, 0.6),
      'noteTextColor': darkMode ? '#1a1a1a' : '#333333',
      'noteBorderColor': ColorUtils.darken(primary, 0.1),

      // Error styling
      'errorBkgColor': tertiary,
      'errorTextColor': text,

      // Generic styling
      'mainBkg': surface,
      'lineColor': _deriveLineColor(background, darkMode),

      // Text outside nodes (titles, labels, many edge texts)
      'textColor': canvasText,
      'titleColor': canvasText,
    };

    // Flowchart
    vars.addAll({
      'nodeTextColor': text, // inside nodes
      'nodeBorder': primaryBorder,
      'clusterBkg': surface,
      'clusterBorder': ColorUtils.lighten(surface, 0.15),
      'defaultLinkColor': vars['lineColor'],
      'edgeLabelBackground': canvasOnDarkSlide ? 'transparent' : '#ffffff',
    });

    // Sequence
    vars.addAll({
      'actorBkg': surface,
      'actorBorder': ColorUtils.lighten(surface, 0.12),
      'actorTextColor': text,
      'actorLineColor': ColorUtils.lighten(surface, 0.12),

      'signalColor': canvasText,
      'signalTextColor': canvasText,

      'labelBoxBkgColor': surface,
      'labelBoxBorderColor': ColorUtils.lighten(surface, 0.15),
      'labelTextColor': text,

      'loopTextColor': canvasText,
      'activationBkgColor': primary,
      'activationBorderColor': primaryBorder,
      'sequenceNumberColor': canvasText,
    });

    // State
    vars.addAll({
      'labelColor': text,
      'altBackground': ColorUtils.lighten(surface, 0.08),
    });

    // Class
    vars['classText'] = canvasText;

    // Pie - complete v11.12.0 spec
    vars.addAll({
      'pieTitleTextSize': '24px',
      'pieTitleTextColor': canvasText,
      'pieLegendTextSize': '16px',
      'pieLegendTextColor': canvasText,
      'pieSectionTextSize': '18px',
      'pieSectionTextColor': '#ffffff',
      'pieStrokeColor': background,
      'pieStrokeWidth': '2px',
      'pieOuterStrokeColor': background,
      'pieOuterStrokeWidth': '2px',
      'pieOpacity': '0.7',
    });

    // Pie slice fills (pie1-pie12)
    for (var i = 0; i < 12; i++) {
      final sliceColor = i < 8 ? gitColors[i] : ColorUtils.lighten(primary, 0.1 * (i - 8));
      vars['pie${i + 1}'] = sliceColor;
    }

    // GitGraph branches 0..7 with inverted and label colors
    for (var i = 0; i < 8; i++) {
      vars['git$i'] = gitColors[i];
      // Inverted colors for highlights
      vars['gitInv$i'] = ColorUtils.contrastColor(
        gitColors[i],
        light: '#ffffff',
        dark: '#000000',
      );
      // Branch label colors
      vars['gitBranchLabel$i'] = canvasText;
    }

    // Git commit/tag styling
    vars.addAll({
      'commitLabelColor': canvasText,
      'commitLabelBackground': surface,
      'commitLabelFontSize': '14px',
      'tagLabelColor': canvasText,
      'tagLabelBackground': primary,
      'tagLabelBorder': primaryBorder,
      'tagLabelFontSize': '14px',
    });

    // Timeline - categorical color scales
    for (var i = 0; i < 12; i++) {
      // Use git colors for scales 0-7, then derive more
      final scaleColor = i < 8 ? gitColors[i] : ColorUtils.lighten(primary, 0.1 * i);
      vars['cScale$i'] = scaleColor;
      vars['cScaleLabel$i'] = ColorUtils.contrastColor(
        scaleColor,
        light: '#ffffff',
        dark: '#000000',
      );
    }

    // Quadrant Chart
    vars.addAll({
      'quadrant1Fill': ColorUtils.lighten(primary, 0.4),
      'quadrant2Fill': ColorUtils.lighten(primary, 0.2),
      'quadrant3Fill': secondary,
      'quadrant4Fill': primary,
      'quadrant1TextFill': canvasText,
      'quadrant2TextFill': canvasText,
      'quadrant3TextFill': canvasText,
      'quadrant4TextFill': ColorUtils.contrastColor(primary, light: '#fff', dark: '#000'),
    });

    // XY Chart (nested config)
    vars['xyChart'] = {
      'backgroundColor': background,
      'titleColor': canvasText,
      'xAxisLabelColor': canvasText,
      'xAxisTitleColor': canvasText,
      'xAxisTickColor': vars['lineColor'],
      'xAxisLineColor': vars['lineColor'],
      'yAxisLabelColor': canvasText,
      'yAxisTitleColor': canvasText,
      'yAxisTickColor': vars['lineColor'],
      'yAxisLineColor': vars['lineColor'],
      'plotColorPalette': gitColors.take(4).join(','),
    };

    // Radar Chart (nested config)
    vars['radar'] = {
      'axisColor': vars['lineColor'],
      'axisStrokeWidth': 1,
      'axisLabelFontSize': '14px',
      'curveOpacity': 0.7,
      'curveStrokeWidth': 2,
      'graticuleColor': vars['lineColor'],
      'graticuleOpacity': 0.2,
      'graticuleStrokeWidth': 1,
      'legendBoxSize': 14,
      'legendFontSize': '14px',
    };

    return vars;
  }

  static String _deriveSurface(String bg, bool dark) =>
      dark ? ColorUtils.lighten(bg, 0.10) : ColorUtils.darken(bg, 0.05);

  static String _deriveLineColor(String bg, bool dark) =>
      dark ? ColorUtils.lighten(bg, 0.45) : ColorUtils.darken(bg, 0.25);

  @override
  String toString() =>
      'MermaidTheme(background: $background, primary: $primary, text: $text, darkMode: $darkMode, canvasOnDarkSlide: $canvasOnDarkSlide)';

  @override
  bool operator ==(Object other) =>
      other is MermaidTheme &&
      other.background == background &&
      other.primary == primary &&
      other.text == text &&
      other.darkMode == darkMode &&
      other.canvasOnDarkSlide == canvasOnDarkSlide &&
      other.canvasTextOverride == canvasTextOverride;

  @override
  int get hashCode => Object.hash(
    background,
    primary,
    text,
    darkMode,
    canvasOnDarkSlide,
    canvasTextOverride,
  );
}
