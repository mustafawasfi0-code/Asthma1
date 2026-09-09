import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// مسحنا الـ show AuthState حتى نكدر نستخدم UserAttributes
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  AppState._() {
    _authSubscription = SupabaseService.authStateChanges?.listen((_) {
      _checkServerMemory(); // أول ما يتغير الدخول، يشيك السيرفر
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
    _checkServerMemory();
  }

  // دالة جديدة: تسأل السيرفر إذا هذا الحساب مكمل معلوماته سابقاً
  void _checkServerMemory() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      if (metadata != null && metadata['onboarding_completed'] == true) {
        onboardingCompleted = true;
        // نحدث ذاكرة التلفون حتى تطابق السيرفر
        SharedPreferences.getInstance().then((p) {
          p.setBool('onboarding_completed', true);
        });
      }
    }
    notifyListeners();
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
    
    // الإضافة السحرية: نحفظ الإنجاز بذاكرة السيرفر حتى ما ينساه أبداً
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'onboarding_completed': true}),
      );
    }
    
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