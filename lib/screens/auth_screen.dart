import 'package:flutter/material.dart';
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
  } catch (e, st) {
  debugPrint('Google sign-in error: $e');
  debugPrint('$st');
  if (mounted) {
    setState(
      () => error = appText(
        'Could not sign in with Google. Please try again.',
        'تعذر تسجيل الدخول عبر جوجل. حاول مرة أخرى.',
      ),
    );
  }
}finally {
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
