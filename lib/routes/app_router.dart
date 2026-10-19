import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../screens/auth_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_screens.dart';
import '../screens/monitoring_screen.dart';
import '../screens/doctor_report_screen.dart';
import '../screens/learn_screens.dart';
import '../screens/inhaler_technique_screens.dart';
import '../screens/secondary_screens.dart';
import '../screens/home_secondary_screens.dart';
import '../screens/update_password_screen.dart'; // شاشة تحديث كلمة المرور الجديدة

// ---------------------------------------------------------------------------
// Direction-aware bottom-tab transitions
// ---------------------------------------------------------------------------
int? _lastTab;
bool _tabSwitching = false;
double _outgoingDir = 1;
final Map<LocalKey, double> _slideDirByPage = {};

/// Builds a bottom-tab page. Moving to a tab on the right slides the new page
/// in from the right (and the old page out to the left); moving left does the
/// opposite. The direction follows what the user sees, so it is mirrored in
/// Arabic where the tab bar runs right-to-left.
CustomTransitionPage<void> _tabPage(
  GoRouterState state,
  int index,
  Widget child,
) {
  final key = state.pageKey;
  final previous = _lastTab;
  if (previous != null && previous != index) {
    final mirrored = AppState.instance.arabic ? -1.0 : 1.0;
    final dir = (index > previous ? 1.0 : -1.0) * mirrored;
    _slideDirByPage[key] = dir;
    _outgoingDir = dir;
    _tabSwitching = true;
    Future<void>.delayed(
      const Duration(milliseconds: 450),
      () => _tabSwitching = false,
    );
  } else {
    _slideDirByPage.putIfAbsent(key, () => 0);
  }
  _lastTab = index;

  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 340),
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      final enterDir = _slideDirByPage[key] ?? 0;
      Widget result = page;
      if (_tabSwitching) {
        // The page being replaced slides away in the opposite direction.
        result = SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-_outgoingDir, 0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ),
          ),
          child: result,
        );
      }
      if (enterDir == 0) {
        return FadeTransition(opacity: animation, child: result);
      }
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(enterDir, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        ),
        child: result,
      );
    },
  );
}

final appRouter = GoRouter(
  refreshListenable: AppState.instance,
  initialLocation: '/auth',
  redirect: (context, state) {
    final path = state.uri.path;
    final authed = AppState.instance.isAuthenticated;
    
    // استثناء مهم: السماح بمرور رابط تغيير الباسورد بدون تسجيل دخول
    if (path == '/reset-callback') return null;

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
    // مسار استقبال رابط إعادة تعيين كلمة المرور
    GoRoute(
      path: '/reset-callback',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const UpdatePasswordScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const OnboardingScreen()),
    ),
    GoRoute(
      path: '/onboarding/medications',
      builder: (context, state) {
        // استلام الكودات الممررة من الشاشة الرئيسية
        final existingCodes = state.extra as List<String>? ?? [];
        
        return _LanguageRefresh(
          builder: (_) => MedicationSelectionScreen(
            fromEdit: state.uri.queryParameters['edit'] == 'true',
            initialCodes: existingCodes, // إرسالها للشاشة
          ),
        );
      },
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
      pageBuilder: (context, state) => _tabPage(
        state,
        0,
        _LanguageRefresh(builder: (_) => DashboardScreen()),
      ),
    ),
    GoRoute(
      path: '/monitoring',
      pageBuilder: (context, state) {
        final tabParam = state.uri.queryParameters['tab'];
        final initialTab = switch (tabParam) {
          null => 0,        // no query param at all → bottom nav bar
          'symptoms' => 1,
          'triggers' => 2,
          _ => 3,            // 'peak-flow', 'inhaler', or anything else
        };
        return _tabPage(
          state,
          1,
          _LanguageRefresh(
            builder: (_) => MonitoringScreen(initialTab: initialTab),
          ),
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
      pageBuilder: (context, state) => _tabPage(
        state,
        2,
        _LanguageRefresh(builder: (_) => ActionPlanScreen()),
      ),
    ),
    GoRoute(
      path: '/learn',
      pageBuilder: (context, state) => _tabPage(
        state,
        3,
        _LanguageRefresh(builder: (_) => LearnScreen()),
      ),
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
      pageBuilder: (context, state) => _tabPage(
        state,
        4,
        _LanguageRefresh(builder: (_) => ProfileScreen()),
      ),
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
    GoRoute(
      path: '/onboarding/pef-result',
      builder: (context, state) =>
          _LanguageRefresh(builder: (_) => const PefResultScreen()),
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