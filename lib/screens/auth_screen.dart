import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
const AuthScreen({super.key});

@override
State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
final _formKey = GlobalKey<FormState>();
final _email = TextEditingController();
final _password = TextEditingController();

bool _isSignUp = false;
bool _loading = false;
bool _obscurePassword = true;

@override
void dispose() {
_email.dispose();
_password.dispose();
super.dispose();
}

void _showError(String message) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message),
    backgroundColor: const Color(0xFFDC2626),
  ),
);
}

Future<void> _submit() async {
final a = AppState.instance.arabic;
if (!(_formKey.currentState?.validate() ?? false)) return;

setState(() => _loading = true);
try {
  final client = Supabase.instance.client;
  final email = _email.text.trim();
  final password = _password.text;

  if (_isSignUp) {
    await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'asthmacare://login-callback',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appText(
            'Account created. Please check your email to verify.',
            'تم إنشاء الحساب. يرجى مراجعة بريدك الإلكتروني للتأكيد.',
          ),
        ),
      ),
    );
    setState(() => _isSignUp = false);
  } else {
    await client.auth.signInWithPassword(email: email, password: password);
  }
} on AuthException catch (e) {
  _showError(e.message);
} catch (e) {
  _showError(
    appText(
      'Something went wrong. Please try again.',
      'حدث خطأ ما. حاول مرة أخرى.',
    ),
  );
} finally {
  if (mounted) setState(() => _loading = false);
}
}

// --- دالة استعادة كلمة المرور الجديدة ---
void _showForgotPasswordDialog() {
final emailController = TextEditingController(text: _email.text);
final a = AppState.instance.arabic;
bool sending = false;

showDialog(
  context: context,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return Directionality(
          textDirection: a ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              a ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a
                      ? 'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.'
                      : 'Enter your email and we will send you a link to reset your password.',
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: a ? 'البريد الإلكتروني' : 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(context),
                child: Text(
                  a ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty) return;
                        setStateDialog(() => sending = true);
                        try {
                          await Supabase.instance.client.auth.resetPasswordForEmail(
                            email,
                            // لاحظ التوجيه الخاص بتغيير الباسورد
                            redirectTo: 'asthmacare://reset-callback', 
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(a
                                  ? 'تم إرسال الرابط إلى بريدك الإلكتروني'
                                  : 'Reset link sent to your email'),
                              backgroundColor: AppColors.blue,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(a ? 'حدث خطأ، حاول مجدداً' : 'Error, please try again'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setStateDialog(() => sending = false);
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(a ? 'إرسال' : 'Send'),
              ),
            ],
          ),
        );
      },
    );
  },
);
}
// ----------------------------------------

String? _validateEmail(String? value) {
final a = AppState.instance.arabic;
final v = value?.trim() ?? '';
if (v.isEmpty) return a ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
if (!valid) return a ? 'أدخل بريداً إلكترونياً صحيحاً' : 'Enter a valid email';
return null;
}

String? _validatePassword(String? value) {
final a = AppState.instance.arabic;
final v = value ?? '';
if (v.isEmpty) return a ? 'أدخل كلمة المرور' : 'Enter your password';
if (v.length < 6) {
  return a
      ? 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل'
      : 'Password must be at least 6 characters';
}
return null;
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
          child: SingleChildScrollView(
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
                const SizedBox(height: 20),
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
                  _isSignUp
                      ? appText('Create an account to get started.', 'أنشئ حساباً للبدء.')
                      : appText('Sign in to continue and keep your data safe.', 'سجّل الدخول للمتابعة وحفظ بياناتك بأمان.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const ValueKey('email_field'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: appText('Email', 'البريد الإلكتروني'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('password_field'),
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _loading ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: appText('Password', 'كلمة المرور'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      
                      // --- الزر الجديد الخاص بنسيان كلمة المرور ---
                      if (!_isSignUp)
                        Align(
                          alignment: a ? Alignment.centerLeft : Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              appText('Forgot Password?', 'نسيت كلمة المرور؟'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      // ----------------------------------------------
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    key: const ValueKey('auth_submit_button'),
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(
                            _isSignUp ? appText('Sign Up', 'إنشاء حساب') : appText('Sign In', 'تسجيل الدخول'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  key: const ValueKey('toggle_auth_mode_button'),
                  onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? appText('Already have an account? Sign in', 'لديك حساب بالفعل؟ سجّل الدخول')
                        : appText("Don't have an account? Sign up", 'ليس لديك حساب؟ أنشئ حساباً'),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  appText(
                    'By continuing you agree to use AsthmaCare responsibly. This app supports self-management and does not replace medical advice.',
                    'بالمتابعة فإنك توافق على استخدام AsthmaCare بمسؤولية. هذا التطبيق لدعم الإدارة الذاتية ولا يحل محل المشورة الطبية.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.5),
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