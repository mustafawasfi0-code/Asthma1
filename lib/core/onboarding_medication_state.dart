import 'package:flutter/foundation.dart';
import '../models/medication.dart';

class OnboardingMedicationState extends ChangeNotifier {
  OnboardingMedicationState._();
  static final instance = OnboardingMedicationState._();

  List<Medication> medications = medicationCatalog;
  final Set<String> selectedCodes = <String>{};

  void setCatalog(List<Medication> value) {
    medications = value;
    notifyListeners();
  }

  void setSelected(Iterable<String> codes) {
    selectedCodes
      ..clear()
      ..addAll(codes);
    notifyListeners();
  }

  void toggle(String code) {
    if (!selectedCodes.add(code)) selectedCodes.remove(code);
    notifyListeners();
  }

  bool get allSelected =>
      medications.isNotEmpty && selectedCodes.length == medications.length;

  void selectAll() {
    selectedCodes
      ..clear()
      ..addAll(medications.map((medication) => medication.code));
    notifyListeners();
  }

  void clearSelection() {
    selectedCodes.clear();
    notifyListeners();
  }

  List<Medication> get selectedMedications =>
      medications
          .where((medication) => selectedCodes.contains(medication.code))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
