import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_radio.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/wizard_option_icon.dart';

void main() {
  test('radio option icons are constrained to the Wizard vocabulary', () {
    final option = InputOption.parse({
      'title': 'Business leaders',
      'icon': 'business',
    });

    expect(option.icon, WizardOptionIcon.business);
    expect(WizardOptionIcon.values, hasLength(12));
    expect(
      () => InputOption.parse({
        'title': 'Unknown option',
        'icon': 'material-home',
      }),
      throwsA(anything),
    );
  });
}
