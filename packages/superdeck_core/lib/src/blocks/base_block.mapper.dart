// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'base_block.dart';

class ContentAlignmentMapper extends EnumMapper<ContentAlignment> {
  ContentAlignmentMapper._();

  static ContentAlignmentMapper? _instance;
  static ContentAlignmentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ContentAlignmentMapper._());
    }
    return _instance!;
  }

  static ContentAlignment fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ContentAlignment decode(dynamic value) {
    switch (value) {
      case 'top_left':
        return ContentAlignment.topLeft;
      case 'top_center':
        return ContentAlignment.topCenter;
      case 'top_right':
        return ContentAlignment.topRight;
      case 'center_left':
        return ContentAlignment.centerLeft;
      case 'center':
        return ContentAlignment.center;
      case 'center_right':
        return ContentAlignment.centerRight;
      case 'bottom_left':
        return ContentAlignment.bottomLeft;
      case 'bottom_center':
        return ContentAlignment.bottomCenter;
      case 'bottom_right':
        return ContentAlignment.bottomRight;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ContentAlignment self) {
    switch (self) {
      case ContentAlignment.topLeft:
        return 'top_left';
      case ContentAlignment.topCenter:
        return 'top_center';
      case ContentAlignment.topRight:
        return 'top_right';
      case ContentAlignment.centerLeft:
        return 'center_left';
      case ContentAlignment.center:
        return 'center';
      case ContentAlignment.centerRight:
        return 'center_right';
      case ContentAlignment.bottomLeft:
        return 'bottom_left';
      case ContentAlignment.bottomCenter:
        return 'bottom_center';
      case ContentAlignment.bottomRight:
        return 'bottom_right';
    }
  }
}

extension ContentAlignmentMapperExtension on ContentAlignment {
  String toValue() {
    ContentAlignmentMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ContentAlignment>(this) as String;
  }
}

class ImageFitMapper extends EnumMapper<ImageFit> {
  ImageFitMapper._();

  static ImageFitMapper? _instance;
  static ImageFitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ImageFitMapper._());
    }
    return _instance!;
  }

  static ImageFit fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ImageFit decode(dynamic value) {
    switch (value) {
      case 'fill':
        return ImageFit.fill;
      case 'contain':
        return ImageFit.contain;
      case 'cover':
        return ImageFit.cover;
      case 'fit_width':
        return ImageFit.fitWidth;
      case 'fit_height':
        return ImageFit.fitHeight;
      case 'none':
        return ImageFit.none;
      case 'scale_down':
        return ImageFit.scaleDown;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ImageFit self) {
    switch (self) {
      case ImageFit.fill:
        return 'fill';
      case ImageFit.contain:
        return 'contain';
      case ImageFit.cover:
        return 'cover';
      case ImageFit.fitWidth:
        return 'fit_width';
      case ImageFit.fitHeight:
        return 'fit_height';
      case ImageFit.none:
        return 'none';
      case ImageFit.scaleDown:
        return 'scale_down';
    }
  }
}

extension ImageFitMapperExtension on ImageFit {
  String toValue() {
    ImageFitMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ImageFit>(this) as String;
  }
}

class DartPadThemeMapper extends EnumMapper<DartPadTheme> {
  DartPadThemeMapper._();

  static DartPadThemeMapper? _instance;
  static DartPadThemeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DartPadThemeMapper._());
    }
    return _instance!;
  }

  static DartPadTheme fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DartPadTheme decode(dynamic value) {
    switch (value) {
      case 'dark_mode':
        return DartPadTheme.darkMode;
      case 'light_mode':
        return DartPadTheme.lightMode;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DartPadTheme self) {
    switch (self) {
      case DartPadTheme.darkMode:
        return 'dark_mode';
      case DartPadTheme.lightMode:
        return 'light_mode';
    }
  }
}

extension DartPadThemeMapperExtension on DartPadTheme {
  String toValue() {
    DartPadThemeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DartPadTheme>(this) as String;
  }
}

class BaseBlockMapper extends ClassMapperBase<BaseBlock> {
  BaseBlockMapper._();

  static BaseBlockMapper? _instance;
  static BaseBlockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BaseBlockMapper._());
      ContentAlignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'BaseBlock';

  static String _$type(BaseBlock v) => v.type;
  static const Field<BaseBlock, String> _f$type = Field('type', _$type);
  static ContentAlignment? _$align(BaseBlock v) => v.align;
  static const Field<BaseBlock, ContentAlignment> _f$align =
      Field('align', _$align, opt: true);
  static int? _$flex(BaseBlock v) => v.flex;
  static const Field<BaseBlock, int> _f$flex = Field('flex', _$flex, opt: true);
  static bool? _$scrollable(BaseBlock v) => v.scrollable;
  static const Field<BaseBlock, bool> _f$scrollable =
      Field('scrollable', _$scrollable, opt: true);

  @override
  final MappableFields<BaseBlock> fields = const {
    #type: _f$type,
    #align: _f$align,
    #flex: _f$flex,
    #scrollable: _f$scrollable,
  };
  @override
  final bool ignoreNull = true;

  static BaseBlock _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('BaseBlock');
  }

  @override
  final Function instantiate = _instantiate;

  static BaseBlock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BaseBlock>(map);
  }

  static BaseBlock fromJson(String json) {
    return ensureInitialized().decodeJson<BaseBlock>(json);
  }
}

mixin BaseBlockMappable {
  String toJson();
  Map<String, dynamic> toMap();
}
