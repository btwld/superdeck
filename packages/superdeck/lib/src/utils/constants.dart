import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const kAspectRatio = 16 / 9;

const _kWidth = 1280.0;
const _kHeight = 720.0;

const kResolution = Size(_kWidth, _kHeight);

const kCanRunProcess = kDebugMode && !kIsWeb;
