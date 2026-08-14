import 'package:asthma_care/core/onboarding_medication_state.dart';
import 'package:asthma_care/models/medication.dart';
import 'package:asthma_care/screens/medication_onboarding_screens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Iraqi and international emergency phone validation', () {
    expect(isValidEmergencyPhone('07701234567'), isTrue);
    expect(isValidEmergencyPhone('+9647701234567'), isTrue);
    expect(isValidEmergencyPhone('0770 123 4567'), isTrue);
    expect(isValidEmergencyPhone('770123'), isFalse);
    expect(isValidEmergencyPhone('+012345678'), isFalse);
  });

  test('select all keeps all eight medications without a limit', () {
    final state = OnboardingMedicationState.instance;
    state.setCatalog(medicationCatalog);
    state.clearSelection();
    state.selectAll();
    expect(state.selectedCodes.length, 8);
    expect(state.selectedMedications.length, 8);
    expect(state.allSelected, isTrue);
  });

  test('medication selection supports multiple values and preserves them', () {
    final state = OnboardingMedicationState.instance;
    state.setSelected(const <String>{});
    state.toggle('ventolin');
    state.toggle('clenil');
    expect(state.selectedCodes, containsAll(<String>['ventolin', 'clenil']));
    expect(state.selectedMedications.length, 2);
    state.toggle('ventolin');
    expect(state.selectedCodes, isNot(contains('ventolin')));
    expect(state.selectedCodes, contains('clenil'));
  });
}
