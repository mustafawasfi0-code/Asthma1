from pathlib import Path
root = Path('.')
# ---------------------------------------------------------------------------
# 1. supabase_service.dart — add Google OAuth + sign out + auth state stream
# ---------------------------------------------------------------------------
(root / 'lib/services/supabase_service.dart').write_text("""import 'package:flutter/foundation.dart' show kIsWeb;
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
""", encoding='utf-8')

# ---------------------------------------------------------------------------
# 2. app_state.dart — track auth state, add signOut()
# ---------------------------------------------------------------------------
(root / 'lib/core/app_state.dart').write_text("""import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  AppState._() {
    _authSubscription = SupabaseService.authStateChanges?.listen((_) {
      notifyListeners();
    });
  }
  static final instance = AppState._();

  StreamSubscription<AuthState>? _authSubscription;

  bool arabic = false, onboardingCompleted = false;

  bool get isAuthenticated => SupabaseService.isSignedIn;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    arabic = p.getBool('arabic') ?? false;
    onboardingCompleted = p.getBool('onboarding_completed') ?? false;
  }

  Future<void> toggleLanguage() async {
    arabic = !arabic;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('arabic', arabic);
  }

  Future<void> restartOnboarding() async {
    onboardingCompleted = false;
    await (await SharedPreferences.getInstance()).setBool(
      'onboarding_completed',
      false,
    );
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboardingCompleted = true;
    await (await SharedPreferences.getInstance()).setBool(
      'onboarding_completed',
      true,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    onboardingCompleted = false;
    await (await SharedPreferences.getInstance()).setBool(
      'onboarding_completed',
      false,
    );
    notifyListeners();
  }
}
""", encoding='utf-8')

# ---------------------------------------------------------------------------
# 3. auth_screen.dart — new Google sign-in screen
# ---------------------------------------------------------------------------
(root / 'lib/screens/auth_screen.dart').write_text("""import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool loading = false;
  String? error;

  Future<void> _continueWithGoogle() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await SupabaseService.signInWithGoogle();
      // On success, AppState's auth-state listener notifies the router,
      // which redirects automatically. Nothing else to do here.
    } catch (_) {
      if (mounted) {
        setState(
          () => error = appText(
            'Could not sign in with Google. Please try again.',
            'تعذر تسجيل الدخول عبر جوجل. حاول مرة أخرى.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    return Directionality(
      textDirection: a ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: AppState.instance.toggleLanguage,
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(a ? 'English' : 'العربية'),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6FF),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 52,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      appText('Welcome to AsthmaCare', 'مرحباً بك في AsthmaCare'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      appText(
                        'Sign in to continue and keep your data safe.',
                        'سجّل الدخول للمتابعة وحفظ بياناتك بأمان.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (error != null) ...[
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        key: const ValueKey('google_sign_in_button'),
                        onPressed: loading ? null : _continueWithGoogle,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: Text(
                          appText('Continue with Google', 'المتابعة عبر جوجل'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      appText(
                        'By continuing you agree to use AsthmaCare responsibly. '
                        'This app supports self-management and does not replace '
                        'medical advice.',
                        'بالمتابعة فإنك توافق على استخدام AsthmaCare بمسؤولية. '
                        'هذا التطبيق لدعم الإدارة الذاتية ولا يحل محل المشورة الطبية.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
""", encoding='utf-8')

# ---------------------------------------------------------------------------
# 4. app_router.dart — add /auth route + redirect gate
# ---------------------------------------------------------------------------
p = root / 'lib/routes/app_router.dart'
s = p.read_text(encoding='utf-8')

s = s.replace(
    "import '../core/app_state.dart';\n",
    "import '../core/app_state.dart';\nimport '../screens/auth_screen.dart';\n",
)

old_router_head = """final appRouter = GoRouter(
  refreshListenable: AppState.instance,
  initialLocation: '/onboarding',
  redirect: (context, state) {
    final path = state.uri.path;
    if (AppState.instance.onboardingCompleted && path == '/onboarding') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const OnboardingScreen()),
    ),"""

new_router_head = """final appRouter = GoRouter(
  refreshListenable: AppState.instance,
  initialLocation: '/auth',
  redirect: (context, state) {
    final path = state.uri.path;
    final authed = AppState.instance.isAuthenticated;
    if (!authed) {
      return path == '/auth' ? null : '/auth';
    }
    if (path == '/auth') {
      return AppState.instance.onboardingCompleted ? '/' : '/onboarding';
    }
    if (AppState.instance.onboardingCompleted && path == '/onboarding') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const AuthScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const OnboardingScreen()),
    ),"""

if old_router_head not in s:
    print('WARNING: app_router.dart redirect block not found — check the file manually.')
else:
    s = s.replace(old_router_head, new_router_head)
p.write_text(s, encoding='utf-8')

# ---------------------------------------------------------------------------
# 5. main_screens.dart — remove the "Start over" FAB and its handler
# ---------------------------------------------------------------------------
p = root / 'lib/screens/main_screens.dart'
s = p.read_text(encoding='utf-8')

old_fab = """        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('start_over_onboarding_fab'),
          heroTag: 'start_over_onboarding_fab',
          onPressed: () => _exitToOnboarding(context),
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.exit_to_app_rounded),
          label: Text(
            appText(
              'Start over',
              '\\u0631\\u062c\\u0648\\u0639 \\u0644\\u0644\\u0628\\u062f\\u0627\\u064a\\u0629',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        bottomNavigationBar: const AppNav(),"""

new_fab = """        bottomNavigationBar: const AppNav(),"""

if old_fab not in s:
    print('WARNING: dashboard FAB block not found — check main_screens.dart manually.')
else:
    s = s.replace(old_fab, new_fab)

old_method = """  Future<void> _exitToOnboarding(BuildContext context) async {
    await AppState.instance.restartOnboarding();
    if (context.mounted) context.go('/onboarding');
  }
"""
if old_method not in s:
    print('WARNING: _exitToOnboarding method not found — check main_screens.dart manually.')
else:
    s = s.replace(old_method, '')

p.write_text(s, encoding='utf-8')

# ---------------------------------------------------------------------------
# 6. secondary_screens.dart — add Logout button + confirm dialog to Profile
# ---------------------------------------------------------------------------
p = root / 'lib/screens/secondary_screens.dart'
s = p.read_text(encoding='utf-8')

s = s.replace(
    "import 'package:go_router/go_router.dart';\n",
    "import 'package:go_router/go_router.dart';\nimport '../core/app_state.dart';\n",
)

old_tail = """              OutlinedButton.icon(
                onPressed: () => c.go('/report'),
                icon: const Icon(Icons.description_outlined),
                label: Text(appText('Doctor Report', 'تقرير الطبيب')),
              ),
            ],
          ),
  );
}

class CommunityScreen extends StatefulWidget {"""

new_tail = """              OutlinedButton.icon(
                onPressed: () => c.go('/report'),
                icon: const Icon(Icons.description_outlined),
                label: Text(appText('Doctor Report', 'تقرير الطبيب')),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const ValueKey('profile_logout_button'),
                onPressed: () => _confirmLogout(c),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  appText('Logout', 'تسجيل الخروج'),
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final a = AppState.instance.arabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a ? 'تسجيل الخروج' : 'Log out'),
        content: Text(
          a
              ? 'هل تريد تسجيل الخروج من حسابك؟'
              : 'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(a ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(a ? 'تسجيل الخروج' : 'Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppState.instance.signOut();
    if (context.mounted) context.go('/auth');
  }
}

class CommunityScreen extends StatefulWidget {"""

if old_tail not in s:
    print('WARNING: ProfileScreen tail block not found — check secondary_screens.dart manually.')
else:
    s = s.replace(old_tail, new_tail)

p.write_text(s, encoding='utf-8')

print('Done. Google sign-in screen added, dashboard FAB removed, Profile logout added.')
