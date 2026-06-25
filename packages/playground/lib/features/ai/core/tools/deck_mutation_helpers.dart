import 'package:superdeck_core/superdeck_core.dart';
import 'package:playground/features/ai/core/ai/schemas/deck_schemas.dart';
import 'package:playground/features/ai/core/ai/services/style_json_serializer.dart';
import 'package:playground/features/ai/core/tools/deck_tools_schemas.dart';
import 'package:playground/features/ai/core/tools/errors.dart';

void validateReadIndex(int index, int slideCount) {
  if (index < 0 || index >= slideCount) {
    throw DeckToolException.slideIndexOutOfRange(
      index: index,
      slideCount: slideCount,
    );
  }
}

void validateInsertIndex(int index, int slideCount) {
  if (index < 0 || index > slideCount) {
    throw DeckToolException.slideInsertIndexInvalid(
      index: index,
      slideCount: slideCount,
    );
  }
}

void ensureUniqueSlideKeyForCreate(List<Slide> slides, String key) {
  final exists = slides.any((slide) => slide.key == key);
  if (exists) {
    throw DeckToolException.slideKeyConflict(key);
  }
}

void ensureUniqueSlideKeyForUpdate(List<Slide> slides, int index, String key) {
  final exists = slides.asMap().entries.any(
    (entry) => entry.key != index && entry.value.key == key,
  );
  if (exists) {
    throw DeckToolException.slideKeyConflict(key);
  }
}

List<Slide> insertSlideAt(List<Slide> slides, Slide slide, int index) {
  validateInsertIndex(index, slides.length);
  final next = List<Slide>.from(slides);
  next.insert(index, slide);
  return next;
}

List<Slide> replaceSlideAt(List<Slide> slides, int index, Slide slide) {
  validateReadIndex(index, slides.length);
  final next = List<Slide>.from(slides);
  next[index] = slide;
  return next;
}

List<Slide> removeSlideAt(List<Slide> slides, int index) {
  validateReadIndex(index, slides.length);
  final next = List<Slide>.from(slides);
  next.removeAt(index);
  return next;
}

List<Slide> moveSlide(List<Slide> slides, int fromIndex, int toIndex) {
  validateReadIndex(fromIndex, slides.length);
  validateReadIndex(toIndex, slides.length);

  if (fromIndex == toIndex) {
    return List<Slide>.from(slides);
  }

  final next = List<Slide>.from(slides);
  final item = next.removeAt(fromIndex);
  next.insert(toIndex, item);
  return next;
}

DeckSnapshotType buildDeckSnapshot(List<Slide> slides, {DeckStyleType? style}) {
  final summaries = List<SlideSummaryType>.generate(slides.length, (index) {
    final slide = slides[index];
    return SlideSummaryType.parse({
      'index': index,
      'key': slide.key,
      if (slide.options?.title case final title?) 'title': title,
    });
  });

  return DeckSnapshotType.parse({
    'totalSlides': slides.length,
    'slides': summaries
        .map((summary) => slideSummarySchema.encode(summary)!)
        .toList(),
    if (style case final currentStyle?)
      'style': serializeDeckStyleForJson(currentStyle),
  });
}
