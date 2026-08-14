import '../services/supabase_service.dart';

class ReminderRepository {
  ({dynamic client, dynamic user}) _session() {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('No active Supabase session');
    }
    return (client: client, user: user);
  }

  Future<List<Map<String, dynamic>>> loadAll() async {
    final session = _session();
    final rows = await session.client
        .from('reminders')
        .select('id, title, time_of_day, enabled, created_at')
        .eq('user_id', session.user.id)
        .order('time_of_day');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> add({required String title, required String time}) async {
    _validate(title, time);
    final session = _session();
    await session.client.from('reminders').insert({
      'user_id': session.user.id,
      'title': title.trim(),
      'time_of_day': time,
      'enabled': true,
    });
  }

  Future<void> update(
    String id, {
    required String title,
    required String time,
  }) async {
    _validate(title, time);
    final session = _session();
    await session.client
        .from('reminders')
        .update({'title': title.trim(), 'time_of_day': time})
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final session = _session();
    await session.client
        .from('reminders')
        .update({'enabled': enabled})
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  Future<void> delete(String id) async {
    final session = _session();
    await session.client
        .from('reminders')
        .delete()
        .eq('id', id)
        .eq('user_id', session.user.id);
  }

  void _validate(String title, String time) {
    if (title.trim().isEmpty || title.trim().length > 120) {
      throw const FormatException('Reminder title is required');
    }
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$').hasMatch(time)) {
      throw const FormatException('Invalid reminder time');
    }
  }
}
