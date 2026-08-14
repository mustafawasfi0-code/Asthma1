import 'package:asthma_care/core/app_state.dart';
import 'package:asthma_care/core/app_theme.dart';
import 'package:asthma_care/routes/app_router.dart';
import 'package:asthma_care/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('internal page frames include a back button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PageFrame(
          title: 'Details',
          subtitle: '',
          showNav: false,
          child: SizedBox(),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('app_back_button')), findsOneWidget);
  });

  testWidgets('theme builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(body: Text('AsthmaCare')),
      ),
    );
    expect(find.text('AsthmaCare'), findsOneWidget);
  });

  testWidgets('language changes immediately on the current route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'arabic': false});
    await AppState.instance.load();
    if (AppState.instance.arabic) {
      await AppState.instance.toggleLanguage();
    }

    appRouter.go('/learn');
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: appRouter, theme: buildTheme()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsWidgets);
    expect(
      find.text('\u0627\u0644\u0639\u0631\u0628\u064a\u0629'),
      findsOneWidget,
    );

    await tester.tap(find.text('\u0627\u0644\u0639\u0631\u0628\u064a\u0629'));
    await tester.pumpAndSettle();

    expect(find.text('\u062a\u0639\u0644\u0651\u0645'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
  });

  testWidgets('quick access routes open the correct destination', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'arabic': false});
    await AppState.instance.load();

    Future<void> pumpRoute(String route) async {
      appRouter.go(route);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter, theme: buildTheme()),
      );
      await tester.pumpAndSettle();
    }

    await pumpRoute('/monitoring?tab=symptoms');
    expect(find.byKey(const ValueKey('save_symptoms')), findsOneWidget);

    appRouter.go('/monitoring?tab=triggers');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save_triggers')), findsOneWidget);

    appRouter.go('/monitoring?tab=peak-flow');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save_pef')), findsOneWidget);

    appRouter.go('/medication');
    await tester.pumpAndSettle();
    expect(find.text('Add Medication'), findsOneWidget);
  });
}
