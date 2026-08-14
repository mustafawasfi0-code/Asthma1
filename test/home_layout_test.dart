import 'package:asthma_care/core/app_state.dart';
import 'package:asthma_care/core/app_theme.dart';
import 'package:asthma_care/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home matches a phone viewport without overflow', (tester) async {
    SharedPreferences.setMockInitialValues({'arabic': true});
    await AppState.instance.load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    appRouter.go('/');
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: appRouter, theme: buildTheme()),
    );
    await tester.pumpAndSettle();

    expect(find.text('أدويتي'), findsOneWidget);
    expect(find.text('قياس PEF'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1800),
      2200,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_weather')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_disclaimer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
