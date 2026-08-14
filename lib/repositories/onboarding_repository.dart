import '../models/emergency_contact.dart';
import '../models/medication.dart';
import '../services/supabase_service.dart';

class OnboardingRepository {
  dynamic get _client {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('No active Supabase session');
    }
    return client;
  }

  String get _userId => SupabaseService.client!.auth.currentUser!.id;

  Future<List<Medication>> loadMedications() async {
    try {
      final rows = await _client
          .from('medications')
          .select()
          .order('sort_order');
      final values = List<Map<String, dynamic>>.from(
        rows,
      ).map(Medication.fromJson).toList();
      if (values.isEmpty) return medicationCatalog;
      final byCode = <String, Medication>{
        for (final medication in medicationCatalog) medication.code: medication,
        for (final medication in values) medication.code: medication,
      };
      final merged = byCode.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return merged;
    } catch (_) {
      return medicationCatalog;
    }
  }

  Future<Set<String>> loadSelectedMedicationCodes() async {
    try {
      final rows = await _client
          .from('user_medications')
          .select('medications(code)')
          .eq('user_id', _userId);
      return List<Map<String, dynamic>>.from(rows)
          .map((row) => (row['medications'] as Map?)?['code']?.toString())
          .whereType<String>()
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveSelectedMedicationCodes(Set<String> codes) async {
    final client = _client;
    await client.from('user_medications').delete().eq('user_id', _userId);
    if (codes.isEmpty) return;
    final rows = await client
        .from('medications')
        .select('id, code')
        .inFilter('code', codes.toList());
    final values = List<Map<String, dynamic>>.from(
      rows,
    ).map((row) => {'user_id': _userId, 'medication_id': row['id']}).toList();
    if (values.isNotEmpty) {
      await client.from('user_medications').insert(values);
    }
  }

  Future<EmergencyContact?> loadEmergencyContact() async {
    final row = await _client
        .from('emergency_contacts')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    return row == null
        ? null
        : EmergencyContact.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    await _client.from('emergency_contacts').upsert({
      'user_id': _userId,
      'contact_name': contact.contactName.trim(),
      'relationship': contact.relationship.trim(),
      'phone_number': contact.phoneNumber.trim(),
      'is_primary': true,
    }, onConflict: 'user_id');
  }

  Future<void> deleteEmergencyContact() async {
    await _client.from('emergency_contacts').delete().eq('user_id', _userId);
  }
}
