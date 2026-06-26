import 'package:superdeck_core/superdeck_core.dart';

import 'deck_tools_schemas.dart';
import 'errors.dart';

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
    throw DeckToolException.slideIndexOutOfRange(
      index: index,
      slideCount: slideCount,
    );
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

  if (fromIndex == toIndex) return List<Slide>.from(slides);

  final next = List<Slide>.from(slides);
  final item = next.removeAt(fromIndex);
  next.insert(toIndex, item);
  return next;
}

DeckSnapshotType buildDeckSnapshot(List<Slide> slides) {
  final summaries = List<SlideSummaryType>.generate(slides.length, (index) {
    final slide = slides[index];
    return SlideSummaryType.parse({
      'index': index,
      if (slide.options?.title case final title?) 'title': title,
    });
  });

  return DeckSnapshotType.parse({
    'totalSlides': slides.length,
    'slides': summaries
        .map((summary) => slideSummarySchema.encode(summary)!)
        .toList(),
  });
}
