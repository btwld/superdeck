import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _goldenDiffTolerance = 0.0015;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  _installGoldenTolerance();
  await testMain();
}

void _installGoldenTolerance() {
  final comparator = goldenFileComparator;
  if (comparator is! LocalFileComparator) return;

  goldenFileComparator = _TolerantGoldenFileComparator(
    comparator.basedir.resolve('__superdeck_pdf_golden_comparator__.dart'),
    precisionTolerance: _goldenDiffTolerance,
  );
}

final class _TolerantGoldenFileComparator extends LocalFileComparator {
  final double _precisionTolerance;

  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         precisionTolerance >= 0 && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _precisionTolerance;

    if (passed) {
      result.dispose();

      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
