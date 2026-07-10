import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const kAspectRatio = 16 / 9;

const _kWidth = 1280.0;
const _kHeight = 720.0;

const kResolution = Size(_kWidth, _kHeight);

/// Opaque backdrop painted behind a slide when no background part is set.
///
/// Guarantees a slide is never transparent: without it, a background-less slide
/// (e.g. a template with no chrome) would show through to whatever is behind it,
/// which bleeds the outgoing/incoming slide through during cross-fade
/// transitions. Matches the app shell letterbox so the default is invisible
/// except during transitions.
const kSlideBackgroundColor = Color(0xFF090909);

const kIsTest = bool.fromEnvironment('FLUTTER_TEST');
const kCanRunProcess = kDebugMode && !kIsWeb && !kIsTest;
