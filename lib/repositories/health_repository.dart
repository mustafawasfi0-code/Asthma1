import '../models/monitoring.dart';
import '../services/supabase_service.dart';

class HealthRepository {
  ({dynamic client, dynamic user}) _session() {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('No active Supabase session');
    }
    return (client: client, user: user);
  }

  Future<void> addMedication(String type, String dosage, String? notes) async {
    if (type.trim().isEmpty || dosage.trim().isEmpty) {
      throw const FormatException('Medication and dosage are required');
    }
    final session = _session();
    await session.client.from('medication_logs').insert({
      'user_id': session.user.id,
      'medication_type': type.trim(),
      'dosage': dosage.trim(),
      'notes': notes?.trim(),
      'taken_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int?> personalBest() async {
    final session = _session();
    final row = await session.client
        .from('profiles')
        .select('personal_best_pef')
        .eq('id', session.user.id)
        .maybeSingle();
    return (row?['personal_best_pef'] as num?)?.toInt();
  }

  Future<PeakFlowAssessment> addPeakFlowSession(List<int> values) async {
    final best = await personalBest();
    final assessment = PeakFlowAssessment.calculate(values, best);
    final session = _session();
    await session.client.from('peak_flow_logs').insert({
      'user_id': session.user.id,
      'reading': assessment.highest,
      'reading_1': values[0],
      'reading_2': values[1],
      'reading_3': values[2],
      'highest_reading': assessment.highest,
      'personal_best_at_measurement': best,
      'zone': assessment.zone.name,
      'measured_at': DateTime.now().toIso8601String(),
    });
    return assessment;
  }

  Future<void> addPeakFlow(int value) =>
      addPeakFlowSession([value, value, value]);

  Future<void> addSymptomLog({
    required List<String> symptoms,
    required int severity,
    String? notes,
  }) async {
    if (symptoms.isEmpty) {
      throw const FormatException('Select at least one symptom');
    }
    if (severity < 0 || severity > 10) {
      throw const FormatException('Severity must be between 0 and 10');
    }
    final session = _session();
    await session.client.from('symptom_logs').insert({
      'user_id': session.user.id,
      'symptoms': symptoms,
      'severity': severity,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'occurred_at': DateTime.now().toIso8601String(),
    });
  }

  // --- التعديل الجوهري هنا: حفظ المثيرات بشكل موحد ومباشر ---
  Future<void> addTriggersLog({required List<String> triggers}) async {
    if (triggers.isEmpty) return;

    final session = _session();
    final userId = session.user.id;
    final now = DateTime.now().toIso8601String();

    // نمر على كل عنصر ونقوم بعمل إدخال مباشر لتفادي أي رفض للدفعة الكلية
    for (final trigger in triggers) {
      await session.client.from('trigger_logs').insert({
        'user_id': userId,
        'triggers': [trigger],
        'created_at': now,
      });
    }
  }

  Future<void> updateSymptom(
    String id, {
    required List<String> symptoms,
    required int severity,
    String? notes,
  }) async {
    if (symptoms.isEmpty || severity < 0 || severity > 10) {
      throw const FormatException('Invalid symptom data');
    }
    final session = _session();
    await session.client
        .from('symptom_logs')
        .update({
          'symptoms': symptoms,
          'severity': severity,
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        })
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<void> updateTrigger(
    String id, {
    required List<String> triggers,String? notes,
  }) async {
    if (triggers.isEmpty) throw const FormatException('Trigger is required');
    final session = _session();
    await session.client
        .from('trigger_logs')
        .update({
          'triggers': triggers,
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        })
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<void> updatePeakFlowSession(String id, List<int> values) async {
    final best = await personalBest();
    final assessment = PeakFlowAssessment.calculate(values, best);
    final session = _session();
    await session.client
        .from('peak_flow_logs')
        .update({
          'reading': assessment.highest,
          'reading_1': values[0],
          'reading_2': values[1],
          'reading_3': values[2],
          'highest_reading': assessment.highest,
          'personal_best_at_measurement': best,
          'zone': assessment.zone.name,
        })
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<void> deletePeakFlow(String id) => _delete('peak_flow_logs', id);
  Future<void> deleteSymptom(String id) => _delete('symptom_logs', id);
  Future<void> deleteTrigger(String id) => _delete('trigger_logs', id);

  Future<void> _delete(String table, String id) async {
    final session = _session();
    await session.client
        .from(table)
        .delete()
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<DoctorReportData> loadDoctorReport() async {
    final session = _session();
    final results = await Future.wait<dynamic>([
      session.client
          .from('profiles')
          .select(
            'name, city, age, sex, height_cm, personal_best_pef, doctor_name, doctor_phone, updated_at',
          )
          .eq('id', session.user.id)
          .maybeSingle(),
      session.client
          .from('emergency_contacts')
          .select('contact_name, relationship, phone_number')
          .eq('user_id', session.user.id)
          .maybeSingle(),
      session.client
          .from('user_medications')
          .select('medications(code, name_ar, name_en, medication_type)')
          .eq('user_id', session.user.id),
      recentPeakFlows(limit: 30),
      recentSymptoms(limit: 30),
      recentTriggers(limit: 30),
    ]);
    final medicationLinks = List<Map<String, dynamic>>.from(results[2]);
    final medications = medicationLinks
        .map((row) => row['medications'])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    return DoctorReportData(
      profile: results[0] == null
          ? null
          : Map<String, dynamic>.from(results[0]),
      emergencyContact: results[1] == null
          ? null
          : Map<String, dynamic>.from(results[1]),
      medications: medications,
      peakFlows: List<Map<String, dynamic>>.from(results[3]),
      symptoms: List<Map<String, dynamic>>.from(results[4]),
      triggers: List<Map<String, dynamic>>.from(results[5]),
    );
  }

  Future<List<Map<String, dynamic>>> recentPeakFlows({int limit = 50}) async {
    final session = _session();
    final rows = await session.client
        .from('peak_flow_logs')
        .select(
          'id, reading, reading_1, reading_2, reading_3, highest_reading, personal_best_at_measurement, zone, measured_at',
        )
        .eq('user_id', session.user.id)
        .order('measured_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> recentSymptoms({int limit = 50}) async {
    final session = _session();
    final rows = await session.client
        .from('symptom_logs')
        .select('id, severity, symptoms, notes, occurred_at')
        .eq('user_id', session.user.id)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }// --- التعديل هنا: توحيد المسميات وضمان التنسيق الصحيح ---
  Future<List<Map<String, dynamic>>> recentTriggers({int limit = 50}) async {
    final session = _session();
    final rows = await session.client
        .from('trigger_logs')
        .select('id, triggers, created_at')
        .eq('user_id', session.user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows).map((row) {
      final copy = Map<String, dynamic>.from(row);
      // تجنباً لأي تعارض مع الواجهة التي قد تبحث عن occurred_at
      copy['occurred_at'] = copy['created_at'];
      return copy;
    }).toList();
  }
}