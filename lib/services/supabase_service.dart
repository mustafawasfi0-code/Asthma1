import 'package:supabase_flutter/supabase_flutter.dart';
// مسحنا استدعاء مكتبة dotenv ومكتبة جوجل

class SupabaseService {
  static bool initialized = false;

  static SupabaseClient? get client =>
      initialized ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    final u = 'https://yvsrmyabauhfkiczktgg.supabase.co';
    final k = 'sb_publishable_25e776eWxZv8nj3I7f5xow_hg06WKAw';

    await Supabase.initialize(
      url: u,
      anonKey: k, 
    );
    initialized = true;
  }

  static Stream<AuthState>? get authStateChanges =>
      initialized ? Supabase.instance.client.auth.onAuthStateChange : null;

  static bool get isSignedIn => 
      client?.auth.currentUser != null;

  static Future<void> signOut() async {
    await client?.auth.signOut();
  }

  static String readableError(Object e) => e is AuthException
      ? e.message
      : e is PostgrestException
      ? e.message
      : 'Something went wrong. Please try again.';
}