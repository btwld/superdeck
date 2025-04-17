// UUID v4 generator
import 'dart:math';

String uuidV4() {
  final random = Random();
  const hexDigits = '0123456789abcdef';

  return List.generate(36, (index) {
    if (index == 8 || index == 13 || index == 18 || index == 23) {
      return '-';
    } else if (index == 14) {
      return '4';
    } else if (index == 19) {
      return hexDigits[(random.nextInt(4) + 8)];
    } else {
      return hexDigits[random.nextInt(16)];
    }
  }).join();
}
