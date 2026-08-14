import 'package:flutter/material.dart';
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
  
}
