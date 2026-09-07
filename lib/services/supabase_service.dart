import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool initialized = false;
  static SupabaseClient? get client =>
      initialized ? Supabase.instance.client : null;

  static bool _googleInitialized = false;

  static Future<void> initialize() async {
    final u = dotenv.env['SUPABASE_URL']?.trim() ?? '',
        k = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (u.isEmpty || k.isEmpty) return;
    await Supabase.initialize(url: u, publishableKey: k);
    initialized = true;

    // webClientId (the "Web application" client) is used on EVERY platform,
    // including Android, so Supabase can verify the token server-side.
    // iosClientId is required on iOS only.
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim() ?? '';
    if (webClientId.isEmpty) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: iosClientId.isEmpty ? null : iosClientId,
        serverClientId: webClientId,
      );
      _googleInitialized = true;
    } catch (_) {
      // Leave false; signInWithGoogle() surfaces a clear error instead.
    }
  }

  static Stream<AuthState>? get authStateChanges =>
      initialized ? Supabase.instance.client.auth.onAuthStateChange : null;

  static bool get isSignedIn => client?.auth.currentUser != null;

  /// Native Google sign-in — no browser, no deep link, no redirect URLs.
  static Future<void> signInWithGoogle() async {
    final c = client;
    if (c == null) throw StateError('Supabase is not initialized');
    if (!_googleInitialized) {
      throw StateError('Google sign-in is not configured (missing client id)');
    }

    final googleUser = await GoogleSignIn.instance.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Could not obtain a Google ID token.');
    }

    String? accessToken;
    try {
      final authorization =
          await googleUser.authorizationClient
                  .authorizationForScopes(['email', 'profile']) ??
              await googleUser.authorizationClient
                  .authorizeScopes(['email', 'profile']);
      accessToken = authorization.accessToken;
    } catch (_) {
      // ID token alone is enough for signInWithIdToken if this fails.
    }

    await c.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<void> signOut() async {
    await client?.auth.signOut();
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  static String readableError(Object e) => e is AuthException
      ? e.message
      : e is PostgrestException
      ? e.message
      : 'Something went wrong. Please try again.';
}