import '../models/home_data.dart';
import '../models/medication.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';

class HomeRepository {
  dynamic get _client {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('No active Supabase session');
    }
    return client;
  }

  String get _userId => SupabaseService.client!.auth.currentUser!.id;

  Future<HomeData> load() async {
    final client = _client;
    final results = await Future.wait<dynamic>([
      client.from('profiles').select().eq('id', _userId).maybeSingle(),
      client
          .from('user_medications')
          .select('medications(*)')
          .eq('user_id', _userId),
      client
          .from('peak_flow_logs')
          .select('id, reading, measured_at')
          .eq('user_id', _userId)
          .order('measured_at', ascending: false)
          .limit(100),
      client
          .from('reminders')
          .select('id, title, time_of_day')
          .eq('user_id', _userId)
          .eq('enabled', true)
          .order('time_of_day'),
      client
          .from('emergency_contacts')
          .select('id')
          .eq('user_id', _userId)
          .limit(1),
    ]);

    final profileRow = results[0];
    final medicationRows = List<Map<String, dynamic>>.from(results[1]);
    final medications =
        medicationRows
            .map((row) => row['medications'])
            .whereType<Map>()
            .map((row) => Medication.fromJson(Map<String, dynamic>.from(row)))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return HomeData(
      profile: profileRow == null
          ? null
          : Profile.fromJson(Map<String, dynamic>.from(profileRow)),
      medications: medications,
      peakFlows: List<Map<String, dynamic>>.from(results[2]),
      reminders: List<Map<String, dynamic>>.from(
        results[3],
      ).map(HomeReminder.fromJson).toList(),
      hasEmergencyContact: (results[4] as List).isNotEmpty,
    );
  }
}
