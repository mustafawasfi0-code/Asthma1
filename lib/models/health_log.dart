class HealthLog {
  const HealthLog({
    this.id,
    required this.kind,
    required this.occurredAt,
    required this.data,
  });
  final String? id;
  final String kind;
  final DateTime occurredAt;
  final Map<String, dynamic> data;
}

class MedicationLog {
  const MedicationLog({
    this.id,
    required this.medicationType,
    required this.dosage,
    this.notes,
  });
  final String? id;
  final String medicationType, dosage;
  final String? notes;
}
