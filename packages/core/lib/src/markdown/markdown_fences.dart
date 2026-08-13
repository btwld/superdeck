/// Parse-phase fenced code blocks.
///
/// SuperDeck hides structural syntax (`---` slide splits and `@` directives)
/// inside fenced code. Slide-split, directive tokenization, and
/// serialize-escape all resolve fences here so they cannot drift apart.
///
/// The rule mirrors what SuperDeck already renders through `package:markdown`
/// (`codeFencePattern`): a fence opens on three or more backticks or tildes,
/// a backtick opener cannot carry backticks in its info string (so
/// ` ```dart {.hero}` opens), and a closer repeats the opening character at
/// least as many times. An unclosed fence extends to the end of the text.
///
/// Two departures from `package:markdown` are deliberate:
///
/// - **Closers keep their info string.** CommonMark rejects an info string on
///   a closer, but SuperDeck decks close fences with ` ```{.code}`. Treating
///   that as "not a closer" leaves the fence open and swallows the following
///   `---`, merging two slides.
/// - **Any leading whitespace opens a fence**, where `package:markdown` allows
///   at most three spaces. Over-hiding is safe here: to the renderer a more
///   deeply indented fence is an indented code block, which is still code.
///   Under-hiding would split a slide in the middle of a code sample.
library;

/// Character ranges of the fenced code blocks in [text], each covering its
/// opening and closing fence lines.
List<({int start, int end})> fencedCodeRanges(String text) => [
  for (final span in _fenceSpans(text))
    (start: span.startOffset, end: span.endOffset),
];

/// Whether [offset] sits inside one of [ranges] (`start <= offset < end`).
bool isInsideFencedCode(int offset, List<({int start, int end})> ranges) {
  for (final range in ranges) {
    if (offset >= range.start && offset < range.end) return true;
  }
  return false;
}

/// Indices of the lines of [text] that sit inside fenced code, including the
/// opening and closing fence lines.
///
/// Indices address `text.split('\n')`, so a line-oriented caller can test
/// membership directly instead of tracking character offsets itself.
Set<int> fencedCodeLines(String text) => {
  for (final span in _fenceSpans(text))
    for (var line = span.startLine; line <= span.endLine; line++) line,
};

typedef _FenceSpan = ({
  int startLine,
  int endLine,
  int startOffset,
  int endOffset,
});

/// Single owner of the open/close state machine. Both public views derive from
/// this so a fence can never be a range in one caller and not a line in another.
List<_FenceSpan> _fenceSpans(String text) {
  final spans = <_FenceSpan>[];
  String? openCharacter;
  var openLength = 0;
  var openLine = 0;
  var openOffset = 0;
  var lastLine = 0;

  _forEachLine(text, (index, start, next, line) {
    lastLine = index;
    final fence = _readFenceLine(line);

    if (openCharacter == null) {
      if (fence != null && fence.canOpen) {
        openCharacter = fence.character;
        openLength = fence.length;
        openLine = index;
        openOffset = start;
      }
      return;
    }

    if (fence != null &&
        fence.character == openCharacter &&
        fence.length >= openLength) {
      spans.add((
        startLine: openLine,
        endLine: index,
        startOffset: openOffset,
        endOffset: next,
      ));
      openCharacter = null;
    }
  });

  if (openCharacter != null) {
    spans.add((
      startLine: openLine,
      endLine: lastLine,
      startOffset: openOffset,
      endOffset: text.length,
    ));
  }

  return spans;
}

/// Visits every line of [text] split on `\n`, so line indices match
/// `text.split('\n')`. A trailing `\r` is dropped from [line] so CRLF input
/// reads the same as LF input.
void _forEachLine(
  String text,
  void Function(int index, int start, int next, String line) visit,
) {
  var index = 0;
  var start = 0;

  while (true) {
    final newline = text.indexOf('\n', start);
    final end = newline == -1 ? text.length : newline;
    final next = newline == -1 ? text.length : newline + 1;
    var line = text.substring(start, end);
    if (line.endsWith('\r')) line = line.substring(0, line.length - 1);

    visit(index, start, next, line);

    if (newline == -1) return;
    index++;
    start = next;
  }
}

({String character, int length, bool canOpen})? _readFenceLine(String line) {
  var i = 0;
  while (i < line.length) {
    final unit = line.codeUnitAt(i);
    if (unit != 0x20 && unit != 0x09) break;
    i++;
  }
  if (i >= line.length) return null;

  final markerUnit = line.codeUnitAt(i);
  if (markerUnit != 0x60 && markerUnit != 0x7E) return null;

  var length = 0;
  while (i < line.length && line.codeUnitAt(i) == markerUnit) {
    length++;
    i++;
  }
  if (length < 3) return null;

  final info = line.substring(i);
  final character = String.fromCharCode(markerUnit);

  return (
    character: character,
    length: length,
    // A backtick opener cannot contain backticks in its info string; a tilde
    // opener may contain anything. Closers are not filtered by `canOpen`.
    canOpen: character == '~' || !info.contains('`'),
  );
}
