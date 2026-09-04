import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

class SupabaseService {
  static bool initialized = false;
  static SupabaseClient? get client =>
      initialized ? Supabase.instance.client : null;

  /// Must match the redirect URL registered in Supabase Dashboard
  /// (Authentication > URL Configuration) AND the URL scheme registered
  /// natively on Android/iOS. See setup notes.
  static const _mobileRedirect = 'io.supabase.asthmacare://login-callback/';

  static Future<void> initialize() async {
    final u = dotenv.env['SUPABASE_URL']?.trim() ?? '',
        k = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (u.isEmpty || k.isEmpty) return;
    await Supabase.initialize(url: u, publishableKey: k);
    initialized = true;
  }

  static Stream<AuthState>? get authStateChanges =>
      initialized ? Supabase.instance.client.auth.onAuthStateChange : null;

  static bool get isSignedIn => client?.auth.currentUser != null;

  static Future<void> signInWithGoogle() async {
    final c = client;
    if (c == null) throw StateError('Supabase is not initialized');
    await c.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : _mobileRedirect,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  static Future<void> signOut() async {
    await client?.auth.signOut();
  }

  static String readableError(Object e) => e is AuthException
      ? e.message
      : e is PostgrestException
      ? e.message
      : 'Something went wrong. Please try again.';
}
