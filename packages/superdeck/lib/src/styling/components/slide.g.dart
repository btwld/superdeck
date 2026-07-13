// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slide.dart';

// **************************************************************************
// SpecGenerator
// **************************************************************************

mixin _$SlideSpec implements Spec<SlideSpec>, Diagnosticable {
  StyleSpec<TextSpec>? get h1;
  StyleSpec<TextSpec>? get h2;
  StyleSpec<TextSpec>? get h3;
  StyleSpec<TextSpec>? get h4;
  StyleSpec<TextSpec>? get h5;
  StyleSpec<TextSpec>? get h6;
  StyleSpec<TextSpec>? get p;
  TextStyle? get a;
  TextStyle? get em;
  TextStyle? get strong;
  TextStyle? get del;
  TextStyle? get img;
  TextStyle? get link;
  TextScaler? get textScaleFactor;
  StyleSpec<MarkdownAlertSpec> get alert;
  BoxDecoration? get horizontalRuleDecoration;
  StyleSpec<MarkdownBlockquoteSpec>? get blockquote;
  StyleSpec<MarkdownListSpec>? get list;
  StyleSpec<MarkdownTableSpec>? get table;
  StyleSpec<MarkdownCodeblockSpec>? get code;
  StyleSpec<MarkdownCheckboxSpec>? get checkbox;
  StyleSpec<BoxSpec> get blockContainer;
  StyleSpec<BoxSpec> get slideContainer;
  StyleSpec<ImageSpec> get image;

  @override
  Type get type => SlideSpec;

  @override
  SlideSpec copyWith({
    StyleSpec<TextSpec>? h1,
    StyleSpec<TextSpec>? h2,
    StyleSpec<TextSpec>? h3,
    StyleSpec<TextSpec>? h4,
    StyleSpec<TextSpec>? h5,
    StyleSpec<TextSpec>? h6,
    StyleSpec<TextSpec>? p,
    TextStyle? a,
    TextStyle? em,
    TextStyle? strong,
    TextStyle? del,
    TextStyle? img,
    TextStyle? link,
    TextScaler? textScaleFactor,
    StyleSpec<MarkdownAlertSpec>? alert,
    BoxDecoration? horizontalRuleDecoration,
    StyleSpec<MarkdownBlockquoteSpec>? blockquote,
    StyleSpec<MarkdownListSpec>? list,
    StyleSpec<MarkdownTableSpec>? table,
    StyleSpec<MarkdownCodeblockSpec>? code,
    StyleSpec<MarkdownCheckboxSpec>? checkbox,
    StyleSpec<BoxSpec>? blockContainer,
    StyleSpec<BoxSpec>? slideContainer,
    StyleSpec<ImageSpec>? image,
  }) {
    return SlideSpec(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      p: p ?? this.p,
      a: a ?? this.a,
      em: em ?? this.em,
      strong: strong ?? this.strong,
      del: del ?? this.del,
      img: img ?? this.img,
      link: link ?? this.link,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      alert: alert ?? this.alert,
      horizontalRuleDecoration:
          horizontalRuleDecoration ?? this.horizontalRuleDecoration,
      blockquote: blockquote ?? this.blockquote,
      list: list ?? this.list,
      table: table ?? this.table,
      code: code ?? this.code,
      checkbox: checkbox ?? this.checkbox,
      blockContainer: blockContainer ?? this.blockContainer,
      slideContainer: slideContainer ?? this.slideContainer,
      image: image ?? this.image,
    );
  }

  @override
  SlideSpec lerp(SlideSpec? other, double t) {
    return SlideSpec(
      h1: h1?.lerp(other?.h1, t),
      h2: h2?.lerp(other?.h2, t),
      h3: h3?.lerp(other?.h3, t),
      h4: h4?.lerp(other?.h4, t),
      h5: h5?.lerp(other?.h5, t),
      h6: h6?.lerp(other?.h6, t),
      p: p?.lerp(other?.p, t),
      a: MixOps.lerp(a, other?.a, t),
      em: MixOps.lerp(em, other?.em, t),
      strong: MixOps.lerp(strong, other?.strong, t),
      del: MixOps.lerp(del, other?.del, t),
      img: MixOps.lerp(img, other?.img, t),
      link: MixOps.lerp(link, other?.link, t),
      textScaleFactor: MixOps.lerpSnap(
        textScaleFactor,
        other?.textScaleFactor,
        t,
      ),
      alert: alert.lerp(other?.alert, t),
      horizontalRuleDecoration: MixOps.lerp(
        horizontalRuleDecoration,
        other?.horizontalRuleDecoration,
        t,
      ),
      blockquote: blockquote?.lerp(other?.blockquote, t),
      list: list?.lerp(other?.list, t),
      table: table?.lerp(other?.table, t),
      code: code?.lerp(other?.code, t),
      checkbox: checkbox?.lerp(other?.checkbox, t),
      blockContainer: blockContainer.lerp(other?.blockContainer, t),
      slideContainer: slideContainer.lerp(other?.slideContainer, t),
      image: image.lerp(other?.image, t),
    );
  }

  @override
  List<Object?> get props => [
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p,
    a,
    em,
    strong,
    del,
    img,
    link,
    textScaleFactor,
    alert,
    horizontalRuleDecoration,
    blockquote,
    list,
    table,
    code,
    checkbox,
    blockContainer,
    slideContainer,
    image,
  ];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SlideSpec &&
            runtimeType == other.runtimeType &&
            propsEquals(props, other.props);
  }

  @override
  int get hashCode => propsHash(runtimeType, props);

  @override
  bool get stringify => true;

  @override
  Map<String, String> getDiff(Equatable other) {
    if (this == other) return const {};

    return propsDiff(props, other.props);
  }

  @override
  String toStringShort() => '$runtimeType';

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      toDiagnosticsNode(
        style: DiagnosticsTreeStyle.singleLine,
      ).toString(minLevel: minLevel);

  @override
  DiagnosticsNode toDiagnosticsNode({
    String? name,
    DiagnosticsTreeStyle? style,
  }) =>
      DiagnosticableNode<Diagnosticable>(name: name, value: this, style: style);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('h1', h1))
      ..add(DiagnosticsProperty('h2', h2))
      ..add(DiagnosticsProperty('h3', h3))
      ..add(DiagnosticsProperty('h4', h4))
      ..add(DiagnosticsProperty('h5', h5))
      ..add(DiagnosticsProperty('h6', h6))
      ..add(DiagnosticsProperty('p', p))
      ..add(DiagnosticsProperty('a', a))
      ..add(DiagnosticsProperty('em', em))
      ..add(DiagnosticsProperty('strong', strong))
      ..add(DiagnosticsProperty('del', del))
      ..add(DiagnosticsProperty('img', img))
      ..add(DiagnosticsProperty('link', link))
      ..add(DiagnosticsProperty('textScaleFactor', textScaleFactor))
      ..add(DiagnosticsProperty('alert', alert))
      ..add(
        DiagnosticsProperty(
          'horizontalRuleDecoration',
          horizontalRuleDecoration,
        ),
      )
      ..add(DiagnosticsProperty('blockquote', blockquote))
      ..add(DiagnosticsProperty('list', list))
      ..add(DiagnosticsProperty('table', table))
      ..add(DiagnosticsProperty('code', code))
      ..add(DiagnosticsProperty('checkbox', checkbox))
      ..add(DiagnosticsProperty('blockContainer', blockContainer))
      ..add(DiagnosticsProperty('slideContainer', slideContainer))
      ..add(DiagnosticsProperty('image', image));
  }
}

@Deprecated(
  'Rename to `_\$SlideSpec` and migrate the class declaration to `class SlideSpec with _\$SlideSpec`. The `_\$SlideSpecMethods` alias will be removed in mix_generator 3.0.',
)
typedef _$SlideSpecMethods = _$SlideSpec; // ignore: unused_element

// **************************************************************************
// SpecStylerGenerator
// **************************************************************************

class SlideStyler extends MixStyler<SlideStyler, SlideSpec> {
  final Prop<StyleSpec<TextSpec>>? $h1;
  final Prop<StyleSpec<TextSpec>>? $h2;
  final Prop<StyleSpec<TextSpec>>? $h3;
  final Prop<StyleSpec<TextSpec>>? $h4;
  final Prop<StyleSpec<TextSpec>>? $h5;
  final Prop<StyleSpec<TextSpec>>? $h6;
  final Prop<StyleSpec<TextSpec>>? $p;
  final Prop<TextStyle>? $a;
  final Prop<TextStyle>? $em;
  final Prop<TextStyle>? $strong;
  final Prop<TextStyle>? $del;
  final Prop<TextStyle>? $img;
  final Prop<TextStyle>? $link;
  final Prop<TextScaler>? $textScaleFactor;
  final Prop<StyleSpec<MarkdownAlertSpec>>? $alert;
  final Prop<BoxDecoration>? $horizontalRuleDecoration;
  final Prop<StyleSpec<MarkdownBlockquoteSpec>>? $blockquote;
  final Prop<StyleSpec<MarkdownListSpec>>? $list;
  final Prop<StyleSpec<MarkdownTableSpec>>? $table;
  final Prop<StyleSpec<MarkdownCodeblockSpec>>? $code;
  final Prop<StyleSpec<MarkdownCheckboxSpec>>? $checkbox;
  final Prop<StyleSpec<BoxSpec>>? $blockContainer;
  final Prop<StyleSpec<BoxSpec>>? $slideContainer;
  final Prop<StyleSpec<ImageSpec>>? $image;

  const SlideStyler.create({
    Prop<StyleSpec<TextSpec>>? h1,
    Prop<StyleSpec<TextSpec>>? h2,
    Prop<StyleSpec<TextSpec>>? h3,
    Prop<StyleSpec<TextSpec>>? h4,
    Prop<StyleSpec<TextSpec>>? h5,
    Prop<StyleSpec<TextSpec>>? h6,
    Prop<StyleSpec<TextSpec>>? p,
    Prop<TextStyle>? a,
    Prop<TextStyle>? em,
    Prop<TextStyle>? strong,
    Prop<TextStyle>? del,
    Prop<TextStyle>? img,
    Prop<TextStyle>? link,
    Prop<TextScaler>? textScaleFactor,
    Prop<StyleSpec<MarkdownAlertSpec>>? alert,
    Prop<BoxDecoration>? horizontalRuleDecoration,
    Prop<StyleSpec<MarkdownBlockquoteSpec>>? blockquote,
    Prop<StyleSpec<MarkdownListSpec>>? list,
    Prop<StyleSpec<MarkdownTableSpec>>? table,
    Prop<StyleSpec<MarkdownCodeblockSpec>>? code,
    Prop<StyleSpec<MarkdownCheckboxSpec>>? checkbox,
    Prop<StyleSpec<BoxSpec>>? blockContainer,
    Prop<StyleSpec<BoxSpec>>? slideContainer,
    Prop<StyleSpec<ImageSpec>>? image,
    super.variants,
    super.modifier,
    super.animation,
  }) : $h1 = h1,
       $h2 = h2,
       $h3 = h3,
       $h4 = h4,
       $h5 = h5,
       $h6 = h6,
       $p = p,
       $a = a,
       $em = em,
       $strong = strong,
       $del = del,
       $img = img,
       $link = link,
       $textScaleFactor = textScaleFactor,
       $alert = alert,
       $horizontalRuleDecoration = horizontalRuleDecoration,
       $blockquote = blockquote,
       $list = list,
       $table = table,
       $code = code,
       $checkbox = checkbox,
       $blockContainer = blockContainer,
       $slideContainer = slideContainer,
       $image = image;

  SlideStyler({
    TextStyler? h1,
    TextStyler? h2,
    TextStyler? h3,
    TextStyler? h4,
    TextStyler? h5,
    TextStyler? h6,
    TextStyler? p,
    TextStyleMix? a,
    TextStyleMix? em,
    TextStyleMix? strong,
    TextStyleMix? del,
    TextStyleMix? img,
    TextStyleMix? link,
    TextScaler? textScaleFactor,
    MarkdownAlertStyler? alert,
    BoxDecoration? horizontalRuleDecoration,
    MarkdownBlockquoteStyler? blockquote,
    MarkdownListStyler? list,
    MarkdownTableStyler? table,
    MarkdownCodeblockStyler? code,
    MarkdownCheckboxStyler? checkbox,
    BoxStyler? blockContainer,
    BoxStyler? slideContainer,
    ImageStyler? image,
    AnimationConfig? animation,
    WidgetModifierConfig? modifier,
    List<VariantStyle<SlideSpec>>? variants,
  }) : this.create(
         h1: Prop.maybeMix(h1),
         h2: Prop.maybeMix(h2),
         h3: Prop.maybeMix(h3),
         h4: Prop.maybeMix(h4),
         h5: Prop.maybeMix(h5),
         h6: Prop.maybeMix(h6),
         p: Prop.maybeMix(p),
         a: Prop.maybeMix(a),
         em: Prop.maybeMix(em),
         strong: Prop.maybeMix(strong),
         del: Prop.maybeMix(del),
         img: Prop.maybeMix(img),
         link: Prop.maybeMix(link),
         textScaleFactor: Prop.maybe(textScaleFactor),
         alert: Prop.maybeMix(alert),
         horizontalRuleDecoration: Prop.maybe(horizontalRuleDecoration),
         blockquote: Prop.maybeMix(blockquote),
         list: Prop.maybeMix(list),
         table: Prop.maybeMix(table),
         code: Prop.maybeMix(code),
         checkbox: Prop.maybeMix(checkbox),
         blockContainer: Prop.maybeMix(blockContainer),
         slideContainer: Prop.maybeMix(slideContainer),
         image: Prop.maybeMix(image),
         variants: variants,
         modifier: modifier,
         animation: animation,
       );

  factory SlideStyler.h1(TextStyler value) => SlideStyler().h1(value);
  factory SlideStyler.h2(TextStyler value) => SlideStyler().h2(value);
  factory SlideStyler.h3(TextStyler value) => SlideStyler().h3(value);
  factory SlideStyler.h4(TextStyler value) => SlideStyler().h4(value);
  factory SlideStyler.h5(TextStyler value) => SlideStyler().h5(value);
  factory SlideStyler.h6(TextStyler value) => SlideStyler().h6(value);
  factory SlideStyler.p(TextStyler value) => SlideStyler().p(value);
  factory SlideStyler.a(TextStyleMix value) => SlideStyler().a(value);
  factory SlideStyler.em(TextStyleMix value) => SlideStyler().em(value);
  factory SlideStyler.strong(TextStyleMix value) => SlideStyler().strong(value);
  factory SlideStyler.del(TextStyleMix value) => SlideStyler().del(value);
  factory SlideStyler.img(TextStyleMix value) => SlideStyler().img(value);
  factory SlideStyler.link(TextStyleMix value) => SlideStyler().link(value);
  factory SlideStyler.textScaleFactor(TextScaler value) =>
      SlideStyler().textScaleFactor(value);
  factory SlideStyler.alert(MarkdownAlertStyler value) =>
      SlideStyler().alert(value);
  factory SlideStyler.horizontalRuleDecoration(BoxDecoration value) =>
      SlideStyler().horizontalRuleDecoration(value);
  factory SlideStyler.blockquote(MarkdownBlockquoteStyler value) =>
      SlideStyler().blockquote(value);
  factory SlideStyler.list(MarkdownListStyler value) =>
      SlideStyler().list(value);
  factory SlideStyler.table(MarkdownTableStyler value) =>
      SlideStyler().table(value);
  factory SlideStyler.code(MarkdownCodeblockStyler value) =>
      SlideStyler().code(value);
  factory SlideStyler.checkbox(MarkdownCheckboxStyler value) =>
      SlideStyler().checkbox(value);
  factory SlideStyler.blockContainer(BoxStyler value) =>
      SlideStyler().blockContainer(value);
  factory SlideStyler.slideContainer(BoxStyler value) =>
      SlideStyler().slideContainer(value);
  factory SlideStyler.image(ImageStyler value) => SlideStyler().image(value);

  /// Sets the h1.
  SlideStyler h1(TextStyler value) {
    return merge(SlideStyler(h1: value));
  }

  /// Sets the h2.
  SlideStyler h2(TextStyler value) {
    return merge(SlideStyler(h2: value));
  }

  /// Sets the h3.
  SlideStyler h3(TextStyler value) {
    return merge(SlideStyler(h3: value));
  }

  /// Sets the h4.
  SlideStyler h4(TextStyler value) {
    return merge(SlideStyler(h4: value));
  }

  /// Sets the h5.
  SlideStyler h5(TextStyler value) {
    return merge(SlideStyler(h5: value));
  }

  /// Sets the h6.
  SlideStyler h6(TextStyler value) {
    return merge(SlideStyler(h6: value));
  }

  /// Sets the p.
  SlideStyler p(TextStyler value) {
    return merge(SlideStyler(p: value));
  }

  /// Sets the a.
  SlideStyler a(TextStyleMix value) {
    return merge(SlideStyler(a: value));
  }

  /// Sets the em.
  SlideStyler em(TextStyleMix value) {
    return merge(SlideStyler(em: value));
  }

  /// Sets the strong.
  SlideStyler strong(TextStyleMix value) {
    return merge(SlideStyler(strong: value));
  }

  /// Sets the del.
  SlideStyler del(TextStyleMix value) {
    return merge(SlideStyler(del: value));
  }

  /// Sets the img.
  SlideStyler img(TextStyleMix value) {
    return merge(SlideStyler(img: value));
  }

  /// Sets the link.
  SlideStyler link(TextStyleMix value) {
    return merge(SlideStyler(link: value));
  }

  /// Sets the textScaleFactor.
  SlideStyler textScaleFactor(TextScaler value) {
    return merge(SlideStyler(textScaleFactor: value));
  }

  /// Sets the alert.
  SlideStyler alert(MarkdownAlertStyler value) {
    return merge(SlideStyler(alert: value));
  }

  /// Sets the horizontalRuleDecoration.
  SlideStyler horizontalRuleDecoration(BoxDecoration value) {
    return merge(SlideStyler(horizontalRuleDecoration: value));
  }

  /// Sets the blockquote.
  SlideStyler blockquote(MarkdownBlockquoteStyler value) {
    return merge(SlideStyler(blockquote: value));
  }

  /// Sets the list.
  SlideStyler list(MarkdownListStyler value) {
    return merge(SlideStyler(list: value));
  }

  /// Sets the table.
  SlideStyler table(MarkdownTableStyler value) {
    return merge(SlideStyler(table: value));
  }

  /// Sets the code.
  SlideStyler code(MarkdownCodeblockStyler value) {
    return merge(SlideStyler(code: value));
  }

  /// Sets the checkbox.
  SlideStyler checkbox(MarkdownCheckboxStyler value) {
    return merge(SlideStyler(checkbox: value));
  }

  /// Sets the blockContainer.
  SlideStyler blockContainer(BoxStyler value) {
    return merge(SlideStyler(blockContainer: value));
  }

  /// Sets the slideContainer.
  SlideStyler slideContainer(BoxStyler value) {
    return merge(SlideStyler(slideContainer: value));
  }

  /// Sets the image.
  SlideStyler image(ImageStyler value) {
    return merge(SlideStyler(image: value));
  }

  /// Sets the animation configuration.
  @override
  SlideStyler animate(AnimationConfig value) {
    return merge(SlideStyler(animation: value));
  }

  /// Sets the style variants.
  @override
  SlideStyler variants(List<VariantStyle<SlideSpec>> value) {
    return merge(SlideStyler(variants: value));
  }

  /// Wraps with a widget modifier.
  @override
  SlideStyler wrap(WidgetModifierConfig value) {
    return merge(SlideStyler(modifier: value));
  }

  /// Sets the widget modifier.
  SlideStyler modifier(WidgetModifierConfig value) {
    return merge(SlideStyler(modifier: value));
  }

  /// Merges with another [SlideStyler].
  @override
  SlideStyler merge(SlideStyler? other) {
    return SlideStyler.create(
      h1: MixOps.merge($h1, other?.$h1),
      h2: MixOps.merge($h2, other?.$h2),
      h3: MixOps.merge($h3, other?.$h3),
      h4: MixOps.merge($h4, other?.$h4),
      h5: MixOps.merge($h5, other?.$h5),
      h6: MixOps.merge($h6, other?.$h6),
      p: MixOps.merge($p, other?.$p),
      a: MixOps.merge($a, other?.$a),
      em: MixOps.merge($em, other?.$em),
      strong: MixOps.merge($strong, other?.$strong),
      del: MixOps.merge($del, other?.$del),
      img: MixOps.merge($img, other?.$img),
      link: MixOps.merge($link, other?.$link),
      textScaleFactor: MixOps.merge($textScaleFactor, other?.$textScaleFactor),
      alert: MixOps.merge($alert, other?.$alert),
      horizontalRuleDecoration: MixOps.merge(
        $horizontalRuleDecoration,
        other?.$horizontalRuleDecoration,
      ),
      blockquote: MixOps.merge($blockquote, other?.$blockquote),
      list: MixOps.merge($list, other?.$list),
      table: MixOps.merge($table, other?.$table),
      code: MixOps.merge($code, other?.$code),
      checkbox: MixOps.merge($checkbox, other?.$checkbox),
      blockContainer: MixOps.merge($blockContainer, other?.$blockContainer),
      slideContainer: MixOps.merge($slideContainer, other?.$slideContainer),
      image: MixOps.merge($image, other?.$image),
      variants: MixOps.mergeVariants($variants, other?.$variants),
      modifier: MixOps.mergeModifier($modifier, other?.$modifier),
      animation: MixOps.mergeAnimation($animation, other?.$animation),
    );
  }

  /// Resolves to [StyleSpec<SlideSpec>] using [context].
  @override
  StyleSpec<SlideSpec> resolve(BuildContext context) {
    final spec = SlideSpec(
      h1: MixOps.resolve(context, $h1),
      h2: MixOps.resolve(context, $h2),
      h3: MixOps.resolve(context, $h3),
      h4: MixOps.resolve(context, $h4),
      h5: MixOps.resolve(context, $h5),
      h6: MixOps.resolve(context, $h6),
      p: MixOps.resolve(context, $p),
      a: MixOps.resolve(context, $a),
      em: MixOps.resolve(context, $em),
      strong: MixOps.resolve(context, $strong),
      del: MixOps.resolve(context, $del),
      img: MixOps.resolve(context, $img),
      link: MixOps.resolve(context, $link),
      textScaleFactor: MixOps.resolve(context, $textScaleFactor),
      alert: MixOps.resolve(context, $alert),
      horizontalRuleDecoration: MixOps.resolve(
        context,
        $horizontalRuleDecoration,
      ),
      blockquote: MixOps.resolve(context, $blockquote),
      list: MixOps.resolve(context, $list),
      table: MixOps.resolve(context, $table),
      code: MixOps.resolve(context, $code),
      checkbox: MixOps.resolve(context, $checkbox),
      blockContainer: MixOps.resolve(context, $blockContainer),
      slideContainer: MixOps.resolve(context, $slideContainer),
      image: MixOps.resolve(context, $image),
    );

    return StyleSpec(
      spec: spec,
      animation: $animation,
      widgetModifiers: $modifier?.resolve(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('h1', $h1))
      ..add(DiagnosticsProperty('h2', $h2))
      ..add(DiagnosticsProperty('h3', $h3))
      ..add(DiagnosticsProperty('h4', $h4))
      ..add(DiagnosticsProperty('h5', $h5))
      ..add(DiagnosticsProperty('h6', $h6))
      ..add(DiagnosticsProperty('p', $p))
      ..add(DiagnosticsProperty('a', $a))
      ..add(DiagnosticsProperty('em', $em))
      ..add(DiagnosticsProperty('strong', $strong))
      ..add(DiagnosticsProperty('del', $del))
      ..add(DiagnosticsProperty('img', $img))
      ..add(DiagnosticsProperty('link', $link))
      ..add(DiagnosticsProperty('textScaleFactor', $textScaleFactor))
      ..add(DiagnosticsProperty('alert', $alert))
      ..add(
        DiagnosticsProperty(
          'horizontalRuleDecoration',
          $horizontalRuleDecoration,
        ),
      )
      ..add(DiagnosticsProperty('blockquote', $blockquote))
      ..add(DiagnosticsProperty('list', $list))
      ..add(DiagnosticsProperty('table', $table))
      ..add(DiagnosticsProperty('code', $code))
      ..add(DiagnosticsProperty('checkbox', $checkbox))
      ..add(DiagnosticsProperty('blockContainer', $blockContainer))
      ..add(DiagnosticsProperty('slideContainer', $slideContainer))
      ..add(DiagnosticsProperty('image', $image));
  }

  @override
  List<Object?> get props => [
    $h1,
    $h2,
    $h3,
    $h4,
    $h5,
    $h6,
    $p,
    $a,
    $em,
    $strong,
    $del,
    $img,
    $link,
    $textScaleFactor,
    $alert,
    $horizontalRuleDecoration,
    $blockquote,
    $list,
    $table,
    $code,
    $checkbox,
    $blockContainer,
    $slideContainer,
    $image,
    $animation,
    $modifier,
    $variants,
  ];
}
