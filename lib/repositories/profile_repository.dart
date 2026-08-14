import '../models/profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  Future<Profile?> getCurrent() async {
    final c = SupabaseService.client, u = c?.auth.currentUser;
    if (c == null || u == null) return null;
    final r = await c.from('profiles').select().eq('id', u.id).maybeSingle();
    return r == null ? null : Profile.fromJson(r);
  }

  Future<void> save(Profile p) async {
    if (p.name.trim().isEmpty ||
        p.age < 1 ||
        p.age > 120 ||
        p.heightCm < 50 ||
        p.heightCm > 250) {
      throw const FormatException('Invalid profile data');
    }
    final c = SupabaseService.client, u = c?.auth.currentUser;
    if (c == null || u == null) {
      throw StateError('No active Supabase session');
    }
    await c.from('profiles').upsert({...p.toJson(), 'id': u.id});
  }

  Future<void> setPersonalBest(int reading) async {
    if (reading < 1 || reading > 1000) {
      throw const FormatException('Invalid peak flow reading');
    }
    final c = SupabaseService.client, u = c?.auth.currentUser;
    if (c == null || u == null) {
      throw StateError('No active Supabase session');
    }
    await c
        .from('profiles')
        .update({'personal_best_pef': reading})
        .eq('id', u.id);
  }

  Future<void> updatePersonalBest(int reading) async {
    if (reading < 1 || reading > 1000) {
      throw const FormatException('Invalid peak flow reading');
    }
    final c = SupabaseService.client, u = c?.auth.currentUser;
    if (c == null || u == null) {
      throw StateError('No active Supabase session');
    }
    final row = await c
        .from('profiles')
        .select('personal_best_pef')
        .eq('id', u.id)
        .single();
    final current = (row['personal_best_pef'] as num?)?.toInt();
    if (current == null || reading > current) {
      await c
          .from('profiles')
          .update({'personal_best_pef': reading})
          .eq('id', u.id);
    }
  }
}
