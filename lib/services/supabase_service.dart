import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool initialized = false;
  static SupabaseClient? get client =>
      initialized ? Supabase.instance.client : null;
  static Future<void> initialize() async {
    final u = dotenv.env['SUPABASE_URL']?.trim() ?? '',
        k = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (u.isEmpty || k.isEmpty) return;
    await Supabase.initialize(url: u, publishableKey: k);
    initialized = true;
    if (Supabase.instance.client.auth.currentSession == null) {
      await Supabase.instance.client.auth.signInAnonymously();
    }
  }

  static String readableError(Object e) => e is AuthException
      ? e.message
      : e is PostgrestException
      ? e.message
      : 'Something went wrong. Please try again.';
}
