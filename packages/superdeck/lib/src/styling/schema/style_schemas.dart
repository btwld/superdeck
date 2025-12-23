import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../markdown_alert_style.dart';
import '../markdown_alert_type_style.dart';
import '../markdown_blockquote_style.dart';
import '../markdown_checkbox_style.dart';
import '../markdown_codeblock_style.dart';
import '../markdown_list_style.dart';
import '../markdown_table_style.dart';
import '../slide_style.dart';

typedef _JsonMap = Map<String, Object?>;

/// Result type from parsing styles.yaml.
/// Produced directly by [StyleSchemas.styleConfigSchema.parse()].
typedef StyleConfiguration = ({
  SlideStyle? baseStyle,
  Map<String, SlideStyle> styles,
});

/// Style schemas for YAML validation and transformation of styles.yaml configuration.
///
/// ## Usage
/// ```dart
/// final yamlMap = convertYamlToMap(yamlString);
/// final config = StyleSchemas.styleConfigSchema.parse(yamlMap);
/// // config is StyleConfiguration with baseStyle and styles ready to use!
/// ```
///
/// ## Architecture: Transforms at Each Level
/// Each schema validates AND transforms to its Flutter type. Nested transforms
/// cascade up, so parent schemas receive already-transformed values.
///
/// Flow: YAML → colorSchema transforms → decorationSchema receives Color →
/// containerSchema receives BoxDecorationMix → etc.
///
/// ## Validation Strategy
/// - **Nested schemas are strict**: Unknown keys fail validation to catch typos
///   (e.g., `fontsize` instead of `fontSize` will error)
/// - **Top-level is permissive**: Unknown keys pass through for forward
///   compatibility (e.g., future `version` key won't break old parsers)
///
/// ## Transform Function Signatures
/// Transform functions use nullable parameters (e.g., `String?`) because the
/// Ack library's `transform()` API requires it. However, values are non-null
/// in practice since validation ensures valid input before transforms run.
class StyleSchemas {
  StyleSchemas._();

  static const _fontWeights = <String, FontWeight>{
    'normal': FontWeight.normal,
    'bold': FontWeight.bold,
    'w100': FontWeight.w100,
    'w200': FontWeight.w200,
    'w300': FontWeight.w300,
    'w400': FontWeight.w400,
    'w500': FontWeight.w500,
    'w600': FontWeight.w600,
    'w700': FontWeight.w700,
    'w800': FontWeight.w800,
    'w900': FontWeight.w900,
  };

  static const _textDecorations = <String, TextDecoration>{
    'none': TextDecoration.none,
    'underline': TextDecoration.underline,
    'lineThrough': TextDecoration.lineThrough,
    'overline': TextDecoration.overline,
  };

  static const _wrapAlignments = <String, WrapAlignment>{
    'start': WrapAlignment.start,
    'end': WrapAlignment.end,
    'center': WrapAlignment.center,
    'spaceBetween': WrapAlignment.spaceBetween,
    'spaceAround': WrapAlignment.spaceAround,
    'spaceEvenly': WrapAlignment.spaceEvenly,
  };

  static final _baseTextCoreProperties = <String, AckSchema<Object>>{
    'fontSize': Ack.double().positive().optional(),
    'fontFamily': Ack.string().optional(),
    'color': colorSchema,
    'height': Ack.double().positive().optional(),
  };

  static final _baseTextProperties = <String, AckSchema<Object>>{
    ..._baseTextCoreProperties,
    'fontWeight': fontWeightSchema,
  };

  // ===========================================================================
  // LEVEL 1: Base Schemas WITH TRANSFORMS
  // ===========================================================================

  /// Validates hex color strings and transforms to [Color].
  /// Accepts: #RRGGBB or #RRGGBBAA
  static final colorSchema = Ack.string()
      .matches(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$')
      .transform(_parseHexToColor)
      .optional();

  /// Validates font weight values and transforms to [FontWeight].
  static final fontWeightSchema = Ack.string()
      .enumString(_fontWeights.keys.toList())
      .transform(_stringToFontWeight)
      .optional();

  /// Validates text decoration values and transforms to [TextDecoration].
  static final textDecorationSchema = Ack.string()
      .enumString(_textDecorations.keys.toList())
      .transform(_stringToTextDecoration)
      .optional();

  /// Validates wrap alignment values and transforms to [WrapAlignment].
  static final alignmentSchema = Ack.string()
      .enumString(_wrapAlignments.keys.toList())
      .transform(_stringToWrapAlignment)
      .optional();

  // ===========================================================================
  // LEVEL 2: Padding Schema WITH TRANSFORM
  // ===========================================================================

  static final _paddingObjectSchema = Ack.object({
    'all': Ack.double().optional(),
    'horizontal': Ack.double().optional(),
    'vertical': Ack.double().optional(),
    'top': Ack.double().optional(),
    'right': Ack.double().optional(),
    'bottom': Ack.double().optional(),
    'left': Ack.double().optional(),
  });

  /// Validates padding and transforms to [EdgeInsetsGeometryMix].
  /// Accepts: number (all sides) or object with all/horizontal/vertical/individual sides.
  /// Precedence: all → horizontal/vertical → individual sides
  static final paddingSchema = Ack.anyOf([
    Ack.double(),
    _paddingObjectSchema,
  ]).transform(_parsePadding).optional();

  // ===========================================================================
  // LEVEL 3: Composite Schemas WITH TRANSFORMS
  // ===========================================================================

  /// Validates decoration and transforms to [BoxDecorationMix].
  /// Note: 'color' is already a Color from colorSchema transform!
  static final decorationSchema = Ack.object({
    'color': colorSchema, // Already Color when present
    'borderRadius': Ack.double().optional(),
  }).transform(_createDecoration).optional();

  /// Validates container and transforms to [BoxStyler].
  /// Note: padding/margin are already EdgeInsetsGeometryMix, decoration is BoxDecorationMix!
  static final containerSchema = Ack.object({
    'padding': paddingSchema, // Already EdgeInsetsGeometryMix
    'margin': paddingSchema, // Already EdgeInsetsGeometryMix
    'decoration': decorationSchema, // Already BoxDecorationMix
  }).transform(_createBoxStyler).optional();

  // ===========================================================================
  // LEVEL 4: Text Schemas WITH TRANSFORMS
  // ===========================================================================

  /// Validates text style (for link, strong, em) and transforms to [TextStyle].
  /// Note: color is Color, fontWeight is FontWeight, decoration is TextDecoration!
  static final textStyleSchema = Ack.object({
    ..._baseTextProperties, // fontSize, fontWeight, fontFamily, color, height
    'letterSpacing': Ack.double().optional(),
    'decoration': textDecorationSchema, // Already TextDecoration
  }).transform(_createTextStyle).optional();

  /// Validates typography (for h1-h6, p) and transforms to [TextStyler].
  /// Note: color is Color, fontWeight is FontWeight!
  static final typographySchema = Ack.object({
    ..._baseTextProperties, // fontSize, fontWeight, fontFamily, color, height
    'paddingBottom': Ack.double().optional(),
  }).transform(_createTextStyler).optional();

  /// Validates code text style and transforms to [TextStyle].
  static final codeTextStyleSchema = Ack.object({
    ..._baseTextCoreProperties, // fontSize, fontFamily, color, height
  }).transform(_createCodeTextStyle).optional();

  /// Validates code style and transforms to [MarkdownCodeblockStyle].
  /// Note: textStyle is already TextStyle, container is already BoxStyler!
  static final codeStyleSchema = Ack.object({
    'textStyle': codeTextStyleSchema, // Already TextStyle
    'container': containerSchema, // Already BoxStyler
  }).transform(_createCodeStyle).optional();

  /// Validates blockquote style and transforms to [MarkdownBlockquoteStyle].
  /// Uses raw schemas for padding/decoration since BlockquoteStyle needs Flutter types.
  static final blockquoteSchema = Ack.object({
    'textStyle': textStyleSchema, // Already TextStyle
    'padding': _paddingObjectSchema.optional(), // Raw padding object
    'decoration': Ack.object({
      'color': colorSchema,
      'borderRadius': Ack.double().optional(),
    }).optional(),
    'alignment': alignmentSchema, // Already WrapAlignment
  }).transform(_createBlockquoteStyle).optional();

  /// Validates list style and transforms to [MarkdownListStyle].
  static final listSchema = Ack.object({
    'bullet': typographySchema, // Already TextStyler
    'text': typographySchema, // Already TextStyler
    'orderedAlignment': alignmentSchema, // Already WrapAlignment
    'unorderedAlignment': alignmentSchema, // Already WrapAlignment
  }).transform(_createListStyle).optional();

  /// Validates checkbox style and transforms to [MarkdownCheckboxStyle].
  /// Note: Icon styling is not exposed in YAML schema (complex type).
  static final checkboxSchema = Ack.object({
    'textStyle': textStyleSchema, // Already TextStyle
  }).transform(_createCheckboxStyle).optional();

  /// Validates table style and transforms to [MarkdownTableStyle].
  /// Note: Simplified - border/columnWidth are complex Flutter types not exposed.
  static final tableSchema = Ack.object({
    'headStyle': textStyleSchema, // Already TextStyle
    'bodyStyle': textStyleSchema, // Already TextStyle
    'padding': _paddingObjectSchema.optional(), // Raw padding
    'cellPadding': _paddingObjectSchema.optional(), // Raw padding
    'cellDecoration': Ack.object({
      'color': colorSchema,
      'borderRadius': Ack.double().optional(),
    }).optional(),
  }).transform(_createTableStyle).optional();

  /// Validates alert type style and transforms to [MarkdownAlertTypeStyle].
  /// Note: icon/containerFlex/headingFlex are complex types not exposed in YAML.
  static final alertTypeSchema = Ack.object({
    'heading': typographySchema, // Already TextStyler
    'description': typographySchema, // Already TextStyler
    'container': containerSchema, // Already BoxStyler
  }).transform(_createAlertTypeStyle).optional();

  /// Validates alert style and transforms to [MarkdownAlertStyle].
  /// Contains 5 alert types: note, tip, important, warning, caution.
  static final alertSchema = Ack.object({
    'note': alertTypeSchema,
    'tip': alertTypeSchema,
    'important': alertTypeSchema,
    'warning': alertTypeSchema,
    'caution': alertTypeSchema,
  }).transform(_createAlertStyle).optional();

  // ===========================================================================
  // LEVEL 5: Slide Style Schema WITH TRANSFORM
  // ===========================================================================

  /// Map of slide style properties - all transform to their Flutter types
  static final Map<String, AckSchema<Object>> _slideStyleProperties = {
    // Typography (h1-h6, p) → TextStyler
    'h1': typographySchema,
    'h2': typographySchema,
    'h3': typographySchema,
    'h4': typographySchema,
    'h5': typographySchema,
    'h6': typographySchema,
    'p': typographySchema,

    // Inline text styles → TextStyle
    'a': textStyleSchema,
    'del': textStyleSchema,
    'img': textStyleSchema,
    'link': textStyleSchema,
    'strong': textStyleSchema,
    'em': textStyleSchema,

    // Code blocks → MarkdownCodeblockStyle
    'code': codeStyleSchema,

    // Block elements
    'blockquote': blockquoteSchema,
    'list': listSchema,
    'checkbox': checkboxSchema,
    'table': tableSchema,
    'alert': alertSchema,

    // Decorations (raw schema for Flutter BoxDecoration output)
    'horizontalRuleDecoration': Ack.object({
      'color': colorSchema,
      'borderRadius': Ack.double().optional(),
    }).optional(),

    // Containers → BoxStyler
    'blockContainer': containerSchema,
    'slideContainer': containerSchema,
  };

  /// Validates slide style and transforms to [SlideStyle].
  /// All nested values are already their Flutter types!
  static final slideStyleSchema =
      Ack.object(_slideStyleProperties).transform(_createSlideStyle);

  /// Validates named style and transforms to named tuple.
  static final namedStyleSchema = Ack.object({
    'name': Ack.string(),
    ..._slideStyleProperties,
  }).transform(_createNamedStyle);

  // ===========================================================================
  // LEVEL 6: Top-Level Schema WITH TRANSFORM
  // ===========================================================================

  /// Top-level schema that validates AND transforms to [StyleConfiguration].
  ///
  /// Use this schema to parse styles.yaml directly into Flutter types:
  /// ```dart
  /// final config = StyleSchemas.styleConfigSchema.parse(yamlMap);
  /// // config.baseStyle is SlideStyle?
  /// // config.styles is Map<String, SlideStyle>
  /// ```
  static final styleConfigSchema = Ack.object(
    {
      'base': slideStyleSchema.optional(),
      'styles': Ack.list(namedStyleSchema).optional(),
    },
    additionalProperties: true,
  )
      .refine(
        _validateUniqueStyleNames,
        message: 'Duplicate style names found in styles list',
      )
      .transform(_transformToStyleConfig);

  // ===========================================================================
  // TRANSFORM FUNCTIONS
  // ===========================================================================

  static T? _read<T>(_JsonMap? data, String key) {
    return data?[key] as T?;
  }

  static double? _double(_JsonMap? data, String key) {
    return (data?[key] as num?)?.toDouble();
  }

  // ---------------------------------------------------------------------------
  // Level 1: Base transforms (String → Flutter type)
  // ---------------------------------------------------------------------------

  /// Transforms hex color string to [Color].
  /// Accepts #RRGGBB (6 digits) or #RRGGBBAA (8 digits).
  static Color _parseHexToColor(String? value) {
    var hex = value!.substring(1); // Remove #
    if (hex.length == 6) {
      // 6-digit: RRGGBB → prepend FF for full alpha
      hex = 'FF$hex';
    } else {
      // 8-digit: RRGGBBAA → convert to AARRGGBB for Color constructor
      final alpha = hex.substring(6, 8);
      final rgb = hex.substring(0, 6);
      hex = '$alpha$rgb';
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Transforms font weight string to [FontWeight].
  static FontWeight _stringToFontWeight(String? value) {
    return _fontWeights[value] ?? FontWeight.normal;
  }

  /// Transforms text decoration string to [TextDecoration].
  static TextDecoration _stringToTextDecoration(String? value) {
    return _textDecorations[value] ?? TextDecoration.none;
  }

  /// Transforms wrap alignment string to [WrapAlignment].
  static WrapAlignment _stringToWrapAlignment(String? value) {
    return _wrapAlignments[value] ?? WrapAlignment.start;
  }

  // ---------------------------------------------------------------------------
  // Level 2: Padding transform
  // ---------------------------------------------------------------------------

  /// Transforms padding value to [EdgeInsetsGeometryMix].
  /// Precedence: all → horizontal/vertical → individual sides.
  static EdgeInsetsGeometryMix _parsePadding(Object? value) {
    return switch (value) {
      num amount => EdgeInsetsGeometryMix.all(amount.toDouble()),
      _JsonMap map when map.containsKey('all') => EdgeInsetsGeometryMix.all(
        (map['all'] as num).toDouble(),
      ),
      _JsonMap map
          when map.containsKey('horizontal') || map.containsKey('vertical') =>
        EdgeInsetsGeometryMix.symmetric(
          horizontal: (map['horizontal'] as num?)?.toDouble() ?? 0,
          vertical: (map['vertical'] as num?)?.toDouble() ?? 0,
        ),
      final _JsonMap map => EdgeInsetsGeometryMix.only(
        top: (map['top'] as num?)?.toDouble(),
        right: (map['right'] as num?)?.toDouble(),
        bottom: (map['bottom'] as num?)?.toDouble(),
        left: (map['left'] as num?)?.toDouble(),
      ),
      _ => throw StateError('Invalid padding value: $value'),
    };
  }

  // ---------------------------------------------------------------------------
  // Level 3: Composite transforms
  // ---------------------------------------------------------------------------

  /// Transforms to [BoxDecorationMix].
  /// Note: data['color'] is already Color (transformed by colorSchema)!
  static BoxDecorationMix _createDecoration(_JsonMap? data) {
    final color = _read<Color>(data, 'color'); // Already transformed!
    final borderRadius = _double(data, 'borderRadius');

    return BoxDecorationMix(
      color: color,
      borderRadius:
          borderRadius != null ? BorderRadiusMix.circular(borderRadius) : null,
    );
  }

  /// Transforms to [BoxStyler].
  /// Note: All nested values are already their Flutter types!
  static BoxStyler _createBoxStyler(_JsonMap? data) {
    return BoxStyler(
      padding: _read<EdgeInsetsGeometryMix>(data, 'padding'),
      margin: _read<EdgeInsetsGeometryMix>(data, 'margin'),
      decoration: _read<BoxDecorationMix>(data, 'decoration'),
    );
  }

  // ---------------------------------------------------------------------------
  // Level 4: Text transforms
  // ---------------------------------------------------------------------------

  /// Transforms to [TextStyle] (for link, strong, em).
  /// Note: color, fontWeight, decoration are already Flutter types!
  static TextStyle _createTextStyle(_JsonMap? data) {
    return TextStyle(
      fontSize: _double(data, 'fontSize'),
      fontWeight: _read<FontWeight>(data, 'fontWeight'),
      fontFamily: _read<String>(data, 'fontFamily'),
      color: _read<Color>(data, 'color'),
      height: _double(data, 'height'),
      letterSpacing: _double(data, 'letterSpacing'),
      decoration: _read<TextDecoration>(data, 'decoration'),
    );
  }

  /// Transforms to [TextStyler] (for h1-h6, p).
  /// Note: color, fontWeight are already Flutter types!
  static TextStyler _createTextStyler(_JsonMap? data) {
    final styler = TextStyler().style(
      TextStyleMix(
        fontSize: _double(data, 'fontSize'),
        fontWeight: _read<FontWeight>(data, 'fontWeight'),
        fontFamily: _read<String>(data, 'fontFamily'),
        color: _read<Color>(data, 'color'),
        height: _double(data, 'height'),
      ),
    );

    final paddingBottom = _double(data, 'paddingBottom');
    if (paddingBottom != null) {
      return styler.wrap(
        WidgetModifierConfig.padding(
          EdgeInsetsGeometryMix.only(bottom: paddingBottom),
        ),
      );
    }
    return styler;
  }

  /// Transforms to [TextStyle] for code blocks.
  static TextStyle _createCodeTextStyle(_JsonMap? data) {
    return TextStyle(
      fontFamily: _read<String>(data, 'fontFamily'),
      fontSize: _double(data, 'fontSize'),
      color: _read<Color>(data, 'color'),
      height: _double(data, 'height'),
    );
  }

  /// Transforms to [MarkdownCodeblockStyle].
  /// Note: textStyle is TextStyle, container is BoxStyler!
  static MarkdownCodeblockStyle _createCodeStyle(_JsonMap? data) {
    return MarkdownCodeblockStyle(
      textStyle: _read<TextStyle>(data, 'textStyle'),
      container: _read<BoxStyler>(data, 'container'),
    );
  }

  /// Transforms to [MarkdownBlockquoteStyle].
  static MarkdownBlockquoteStyle _createBlockquoteStyle(_JsonMap? data) {
    // Parse padding from raw object
    final paddingData = data?['padding'] as _JsonMap?;
    final padding = paddingData != null ? _parseEdgeInsets(paddingData) : null;

    // Parse decoration from raw object (color is already transformed)
    final decorationData = data?['decoration'] as _JsonMap?;
    final decoration = decorationData != null
        ? BoxDecoration(
            color: decorationData['color'] as Color?,
            borderRadius: decorationData['borderRadius'] != null
                ? BorderRadius.circular(
                    (decorationData['borderRadius'] as num).toDouble(),
                  )
                : null,
          )
        : null;

    return MarkdownBlockquoteStyle(
      textStyle: _read<TextStyle>(data, 'textStyle'),
      padding: padding,
      decoration: decoration,
      alignment: _read<WrapAlignment>(data, 'alignment'),
    );
  }

  /// Transforms to [MarkdownListStyle].
  static MarkdownListStyle _createListStyle(_JsonMap? data) {
    return MarkdownListStyle(
      bullet: _read<TextStyler>(data, 'bullet'),
      text: _read<TextStyler>(data, 'text'),
      orderedAlignment: _read<WrapAlignment>(data, 'orderedAlignment'),
      unorderedAlignment: _read<WrapAlignment>(data, 'unorderedAlignment'),
    );
  }

  /// Transforms to [MarkdownCheckboxStyle].
  static MarkdownCheckboxStyle _createCheckboxStyle(_JsonMap? data) {
    return MarkdownCheckboxStyle(
      textStyle: _read<TextStyle>(data, 'textStyle'),
    );
  }

  /// Transforms to [MarkdownTableStyle].
  static MarkdownTableStyle _createTableStyle(_JsonMap? data) {
    final paddingData = data?['padding'] as _JsonMap?;
    final cellPaddingData = data?['cellPadding'] as _JsonMap?;
    final cellDecorationData = data?['cellDecoration'] as _JsonMap?;

    return MarkdownTableStyle(
      headStyle: _read<TextStyle>(data, 'headStyle'),
      bodyStyle: _read<TextStyle>(data, 'bodyStyle'),
      padding: paddingData != null ? _parseEdgeInsets(paddingData) : null,
      cellPadding:
          cellPaddingData != null ? _parseEdgeInsets(cellPaddingData) : null,
      cellDecoration: cellDecorationData != null
          ? BoxDecoration(
              color: cellDecorationData['color'] as Color?,
              borderRadius: cellDecorationData['borderRadius'] != null
                  ? BorderRadius.circular(
                      (cellDecorationData['borderRadius'] as num).toDouble(),
                    )
                  : null,
            )
          : null,
    );
  }

  /// Transforms to [MarkdownAlertTypeStyle].
  static MarkdownAlertTypeStyle _createAlertTypeStyle(_JsonMap? data) {
    return MarkdownAlertTypeStyle(
      heading: _read<TextStyler>(data, 'heading'),
      description: _read<TextStyler>(data, 'description'),
      container: _read<BoxStyler>(data, 'container'),
    );
  }

  /// Transforms to [MarkdownAlertStyle].
  static MarkdownAlertStyle _createAlertStyle(_JsonMap? data) {
    return MarkdownAlertStyle(
      note: _read<MarkdownAlertTypeStyle>(data, 'note'),
      tip: _read<MarkdownAlertTypeStyle>(data, 'tip'),
      important: _read<MarkdownAlertTypeStyle>(data, 'important'),
      warning: _read<MarkdownAlertTypeStyle>(data, 'warning'),
      caution: _read<MarkdownAlertTypeStyle>(data, 'caution'),
    );
  }

  /// Helper to parse BoxDecoration from raw data.
  static BoxDecoration? _parseBoxDecoration(_JsonMap? data) {
    if (data == null) return null;
    return BoxDecoration(
      color: data['color'] as Color?,
      borderRadius: data['borderRadius'] != null
          ? BorderRadius.circular((data['borderRadius'] as num).toDouble())
          : null,
    );
  }

  /// Helper to parse EdgeInsets from raw padding object.
  static EdgeInsets _parseEdgeInsets(_JsonMap data) {
    if (data.containsKey('all')) {
      return EdgeInsets.all((data['all'] as num).toDouble());
    }
    if (data.containsKey('horizontal') || data.containsKey('vertical')) {
      return EdgeInsets.symmetric(
        horizontal: (data['horizontal'] as num?)?.toDouble() ?? 0,
        vertical: (data['vertical'] as num?)?.toDouble() ?? 0,
      );
    }
    return EdgeInsets.only(
      top: (data['top'] as num?)?.toDouble() ?? 0,
      right: (data['right'] as num?)?.toDouble() ?? 0,
      bottom: (data['bottom'] as num?)?.toDouble() ?? 0,
      left: (data['left'] as num?)?.toDouble() ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Level 5: Slide style transform
  // ---------------------------------------------------------------------------

  /// Transforms to [SlideStyle].
  /// Note: All values are already their Flutter types!
  static SlideStyle _createSlideStyle(_JsonMap? data) {
    T? get<T>(String key) => data?[key] as T?;

    return SlideStyle(
      h1: get('h1'),
      h2: get('h2'),
      h3: get('h3'),
      h4: get('h4'),
      h5: get('h5'),
      h6: get('h6'),
      p: get('p'),
      a: get('a'),
      del: get('del'),
      img: get('img'),
      link: get('link'),
      strong: get('strong'),
      em: get('em'),
      code: get('code'),
      blockquote: get('blockquote'),
      list: get('list'),
      checkbox: get('checkbox'),
      table: get('table'),
      alert: get('alert'),
      horizontalRuleDecoration: _parseBoxDecoration(
        data?['horizontalRuleDecoration'] as _JsonMap?,
      ),
      blockContainer: get('blockContainer'),
      slideContainer: get('slideContainer'),
    );
  }

  /// Creates a named style tuple from validated data.
  /// Note: data is non-null in practice (validation ensures valid input).
  static ({String name, SlideStyle style}) _createNamedStyle(
    _JsonMap? data,
  ) {
    final name = data!['name'] as String;
    // Create SlideStyle from all properties except 'name'
    final styleData = _JsonMap.from(data)..remove('name');
    return (name: name, style: _createSlideStyle(styleData));
  }

  // ---------------------------------------------------------------------------
  // Level 6: Top-level validation and transform
  // ---------------------------------------------------------------------------

  /// Validates that style names are unique.
  static bool _validateUniqueStyleNames(Map<String, dynamic>? config) {
    final styles = config?['styles'];
    if (styles is! List || styles.isEmpty) return true;

    final names = <String>{};
    for (final item in styles) {
      final name = switch (item) {
        (name: final String name, style: final SlideStyle _) => name,
        {'name': final String name} => name,
        _ => null,
      };

      if (name == null) continue;
      if (!names.add(name)) return false;
    }

    return true;
  }

  /// Transforms to [StyleConfiguration].
  /// Note: base is SlideStyle, styles is list of named tuples!
  static StyleConfiguration _transformToStyleConfig(
    Map<String, dynamic>? data,
  ) {
    // 'base' is already a SlideStyle from slideStyleSchema transform
    final baseStyle = data?['base'] as SlideStyle?;

    // 'styles' is already a List of named tuples from namedStyleSchema transform
    final styles = switch (data) {
      {'styles': final List stylesList} => {
          for (final item in stylesList)
            if (item case (name: final String name, style: final SlideStyle style))
              name: style,
        },
      _ => <String, SlideStyle>{},
    };

    return (baseStyle: baseStyle, styles: styles);
  }
}
