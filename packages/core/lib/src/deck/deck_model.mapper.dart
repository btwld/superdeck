// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck_model.dart';

class DeckMapper extends ClassMapperBase<Deck> {
  DeckMapper._();

  static DeckMapper? _instance;
  static DeckMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckMapper._());
      SlideMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Deck';

  static List<Slide> _$slides(Deck v) => v.slides;
  static const Field<Deck, List<Slide>> _f$slides = Field('slides', _$slides);

  @override
  final MappableFields<Deck> fields = const {#slides: _f$slides};

  static Deck _instantiate(DecodingData data) {
    return Deck(slides: data.dec(_f$slides));
  }

  @override
  final Function instantiate = _instantiate;

  static Deck fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Deck>(map);
  }

  static Deck fromJson(String json) {
    return ensureInitialized().decodeJson<Deck>(json);
  }
}

mixin DeckMappable {
  String toJson() {
    return DeckMapper.ensureInitialized().encodeJson<Deck>(this as Deck);
  }

  Map<String, dynamic> toMap() {
    return DeckMapper.ensureInitialized().encodeMap<Deck>(this as Deck);
  }

  DeckCopyWith<Deck, Deck, Deck> get copyWith =>
      _DeckCopyWithImpl<Deck, Deck>(this as Deck, $identity, $identity);
  @override
  String toString() {
    return DeckMapper.ensureInitialized().stringifyValue(this as Deck);
  }

  @override
  bool operator ==(Object other) {
    return DeckMapper.ensureInitialized().equalsValue(this as Deck, other);
  }

  @override
  int get hashCode {
    return DeckMapper.ensureInitialized().hashValue(this as Deck);
  }
}

extension DeckValueCopy<$R, $Out> on ObjectCopyWith<$R, Deck, $Out> {
  DeckCopyWith<$R, Deck, $Out> get $asDeck =>
      $base.as((v, t, t2) => _DeckCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckCopyWith<$R, $In extends Deck, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Slide, SlideCopyWith<$R, Slide, Slide>> get slides;
  $R call({List<Slide>? slides});
  DeckCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DeckCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Deck, $Out>
    implements DeckCopyWith<$R, Deck, $Out> {
  _DeckCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Deck> $mapper = DeckMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Slide, SlideCopyWith<$R, Slide, Slide>> get slides =>
      ListCopyWith(
        $value.slides,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(slides: v),
      );
  @override
  $R call({List<Slide>? slides}) =>
      $apply(FieldCopyWithData({if (slides != null) #slides: slides}));
  @override
  Deck $make(CopyWithData data) =>
      Deck(slides: data.get(#slides, or: $value.slides));

  @override
  DeckCopyWith<$R2, Deck, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DeckCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

