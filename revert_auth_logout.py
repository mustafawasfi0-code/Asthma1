from pathlib import Path
root=Path(r'C:\Projects\flutter_app')

# app_state: restore simple state
(root/'lib/core/app_state.dart').write_text("""import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();
  bool arabic = false, onboardingCompleted = false;
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

  Future<void> finishOnboarding() async {
    onboardingCompleted = true;
    await (await SharedPreferences.getInstance()).setBool(
      'onboarding_completed',
      true,
    );
    notifyListeners();
  }
}
""", encoding='utf-8')

# router remove auth import, redirect block, route
p=root/'lib/routes/app_router.dart'
s=p.read_text(encoding='utf-8')
s=s.replace("import '../screens/auth_screen.dart';\n", '')
s=s.replace("    if (AppState.instance.showAuthOnStart && path == '/onboarding') {\n      return '/auth';\n    }\n", '')
s=s.replace("    GoRoute(\n      path: '/auth',\n      builder: (context, state) =>\n          _LanguageRefresh(builder: (_) => const AuthScreen()),\n    ),\n", '')
p.write_text(s,encoding='utf-8')

# main screen remove auth import, signOut method, signOut button block
p=root/'lib/screens/main_screens.dart'
s=p.read_text(encoding='utf-8')
s=s.replace("import '../repositories/auth_repository.dart';\n", '')
start=s.find('  Future<void> _signOutToAuth(BuildContext context) async {')
if start!=-1:
    end=s.find('\n  @override\n  Widget build', start)
    s=s[:start]+s[end+1:]
start=s.find("                          const SizedBox(height: 12),\n                          SizedBox(\n                            width: double.infinity,\n                            height: 44,\n                            child: FilledButton.icon(\n                              key: const ValueKey('home_sign_out_button'),")
if start!=-1:
    end=s.find("                          if (loading) ...[", start)
    s=s[:start]+s[end:]
p.write_text(s,encoding='utf-8')

# secondary remove auth import, app_state import if only for auth, _openAccount, account card
p=root/'lib/screens/secondary_screens.dart'
s=p.read_text(encoding='utf-8')
s=s.replace("import '../repositories/auth_repository.dart';\n", '')
s=s.replace("import '../core/app_state.dart';\n", '')
start=s.find('  Future<void> _openAccount(BuildContext context) async {')
if start!=-1:
    end=s.find('\n  Future<void> _save(BuildContext context) async {', start)
    s=s[:start]+s[end+1:]
start=s.find("              AppCard(\n                child: Builder(\n                  builder: (context) {")
if start!=-1:
    end=s.find("              AppCard(\n                child: Column(\n                  children: [", start)
    s=s[:start]+s[end:]
p.write_text(s,encoding='utf-8')

# widget test remove auth import and test block
p=root/'test/widget_test.dart'
s=p.read_text(encoding='utf-8')
s=s.replace("import 'package:asthma_care/screens/auth_screen.dart';\n", '')
start=s.find("\n  testWidgets('auth screen validates")
if start!=-1:
    end=s.find('\n}', start)
    # remove until before final main closing brace, keep one closing brace
    s=s[:start]+'\n}'
p.write_text(s,encoding='utf-8')

# delete auth files
for rel in ['lib/screens/auth_screen.dart','lib/repositories/auth_repository.dart']:
    f=root/rel
    if f.exists():
        f.unlink()
print('reverted auth/logout')
