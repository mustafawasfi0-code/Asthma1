import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_screens.dart';
import '../screens/monitoring_screen.dart';
import '../screens/doctor_report_screen.dart';
import '../screens/learn_screens.dart';
import '../screens/inhaler_technique_screens.dart';
import '../screens/secondary_screens.dart';
import '../screens/home_secondary_screens.dart';

final appRouter = GoRouter(
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
    ),
    GoRoute(
      path: '/onboarding/medications',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const MedicationSelectionScreen()),
    ),
    GoRoute(
      path: '/onboarding/medications/info/:index',
      builder: (context, state) => _LanguageRefresh(
        builder: (_) => MedicationInfoScreen(
          index: int.tryParse(state.pathParameters['index'] ?? '') ?? 0,
        ),
      ),
    ),
    GoRoute(
      path: '/onboarding/emergency-contact',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const EmergencyContactScreen()),
    ),
    GoRoute(
      path: '/profile/emergency-contact',
      builder: (context, state) => _LanguageRefresh(
        builder: (_) => const EmergencyContactScreen(onboarding: false),
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => DashboardScreen()),
    ),
    GoRoute(
  path: '/monitoring',
  builder: (context, state) {
    final tabParam = state.uri.queryParameters['tab'];
    final initialTab = switch (tabParam) {
      null => 0,        // no query param at all → bottom nav bar
      'symptoms' => 1,
      'triggers' => 2,
      _ => 3,            // 'peak-flow', 'inhaler', or anything else
    };
    return _LanguageRefresh(
      builder: (_) => MonitoringScreen(initialTab: initialTab),
    );
  },
),
    GoRoute(
      path: '/monitoring/report',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const DoctorReportScreen()),
    ),
    GoRoute(
      path: '/action-plan',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => ActionPlanScreen()),
    ),
    GoRoute(
      path: '/learn',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => LearnScreen()),
    ),
    GoRoute(
      path: '/learn/inhaler-technique',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const InhalerDeviceListScreen()),
    ),
    GoRoute(
      path: '/learn/inhaler-technique/:deviceId',
      builder: (context, state) => _LanguageRefresh(
        builder: (_) => InhalerDeviceDetailScreen(
          deviceId: state.pathParameters['deviceId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/learn/pef-technique',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => TechniqueScreen(pef: true)),
    ),
    GoRoute(
      path: '/technique',
      redirect: (context, state) => '/learn/inhaler-technique',
    ),
    GoRoute(
      path: '/pef-technique',
      redirect: (context, state) => '/learn/pef-technique',
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => ProfileScreen()),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => CommunityScreen()),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const DoctorReportScreen()),
    ),
    GoRoute(
      path: '/medications/info/:code',
      builder: (context, state) => _LanguageRefresh(
        builder: (_) =>
            MedicationDetailsScreen(code: state.pathParameters['code'] ?? ''),
      ),
    ),
    GoRoute(
  path: '/onboarding/medications/how-to-use/:index',
  builder: (context, state) => _LanguageRefresh(
    builder: (_) => MedicationHowToUseScreen(
      index: int.tryParse(state.pathParameters['index'] ?? '') ?? 0,
    ),
  ),
),
    GoRoute(
      path: '/reminders',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const RemindersScreen()),
    ),
    GoRoute(
      path: '/medication',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => MedicationScreen()),
    ),
    GoRoute(
  path: '/onboarding/triggers',
  builder: (context, state) => const TriggersScreen(),
),
  ],
);

class _LanguageRefresh extends StatelessWidget {
  const _LanguageRefresh({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) => builder(context),
  );
}
