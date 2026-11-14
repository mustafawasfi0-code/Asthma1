// lib/data/medication_inhaler_map.dart
//
// Connects the medications a patient selected to the inhaler technique guides
// in `inhaler_devices.dart`, so the Technique screen only shows what is
// relevant to them.
//
// To change which guide(s) a medication opens, edit [_medicationDevices] below
// (use the device ids from inhaler_devices.dart).
import '../models/medication.dart';
import 'inhaler_devices.dart';

/// Medications that have a matching guide in `inhaler_devices.dart`.
const Map<String, List<String>> _medicationDevices = {
  // Pressurised metered-dose inhalers (with or without a spacer)
  'ventolin': ['pmdi-alone', 'pmdi-spacer'],
  'clenil': ['pmdi-alone', 'pmdi-spacer'],
  'foster': ['pmdi-alone', 'pmdi-spacer'],
  'ipratropium': ['pmdi-alone', 'pmdi-spacer'],
  'salres': ['pmdi-alone', 'pmdi-spacer'],
  'pralas': ['pmdi-alone', 'pmdi-spacer'],
  'foracort': ['pmdi-alone', 'pmdi-spacer'],
  // Dry powder inhalers
  'symbicort': ['turbuhaler'],
  'pulmicort': ['turbuhaler'],
  'seretide': ['accuhaler'], // Seretide Diskus = Accuhaler
  'fobumix': ['easyhaler'],
};

/// Medications taken as tablets: there is no inhaler technique to show.
const Set<String> _noInhalerMedications = {'montelukast', 'prednisolone'};

final Map<String, InhalerDevice> _syntheticDevices = {};

/// Builds a guide from the medication's own "how to use" steps. Used for
/// inhalers that are not in `inhaler_devices.dart` (e.g. Elpenhaler, capsule
/// inhalers such as Brontio / Respiramol / Airtide).
InhalerDevice _deviceFromMedication(Medication m) {
  final id = 'med-${m.code}';
  return _syntheticDevices[id] ??= InhalerDevice(
    id: id,
    nameEn: m.nameEn,
    nameAr: m.nameAr,
    categoryId: 'my_medication',
    categoryEn: m.descriptionEn,
    categoryAr: m.descriptionAr,
    requiresPriming: false,
    hasDoseCounter: false,
    requiresShaking: false,
    quickBreath: m.stepsEn.any((s) => s.toLowerCase().contains('quickly')),
    stepsEn: m.stepsEn,
    stepsAr: m.stepsAr.isEmpty ? m.stepsEn : m.stepsAr,
  );
}

/// The technique guide(s) that apply to [medication]. Empty for tablets.
List<InhalerDevice> inhalerGuidesFor(Medication medication) {
  if (_noInhalerMedications.contains(medication.code)) return const [];
  final ids = _medicationDevices[medication.code];
  if (ids != null) {
    return [
      for (final id in ids)
        for (final device in inhalerDevices)
          if (device.id == id) device,
    ];
  }
  if (medication.stepsEn.isEmpty) return const [];
  return [_deviceFromMedication(medication)];
}

/// Finds a guide by id: either a standard device or a medication-based guide.
InhalerDevice? resolveInhalerDevice(String id) {
  for (final device in inhalerDevices) {
    if (device.id == id) return device;
  }
  final cached = _syntheticDevices[id];
  if (cached != null) return cached;
  if (id.startsWith('med-')) {
    final code = id.substring(4);
    for (final medication in medicationCatalog) {
      if (medication.code == code) return _deviceFromMedication(medication);
    }
  }
  return null;
}