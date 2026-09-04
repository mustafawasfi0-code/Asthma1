import 'dart:async';
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
