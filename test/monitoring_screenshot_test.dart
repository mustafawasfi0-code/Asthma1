import 'dart:io';
import 'dart:ui';

import 'package:asthma_care/core/app_state.dart';
import 'package:asthma_care/core/app_theme.dart';
import 'package:asthma_care/models/monitoring.dart';
import 'package:asthma_care/screens/monitoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fontLoader = FontLoader('SegoeUI')
      ..addFont(rootBundle.load('assets/fonts/segoeui.ttf'))
      ..addFont(rootBundle.load('assets/fonts/segoeuib.ttf'));
    await fontLoader.load();
    final iconBytes = await File(
      r'C:\sro\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    ).readAsBytes();
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.sublistView(Uint8List.fromList(iconBytes))),
      );
    await iconLoader.load();
  });

  Future<void> pumpMonitoring(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'arabic': true});
    await AppState.instance.load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final router = GoRouter(
      initialLocation: '/monitoring',
      routes: [
        GoRoute(
          path: '/monitoring',
          builder: (_, _) =>
              const MonitoringScreen(previewReadings: [900, 600, 800]),
        ),
        GoRoute(
          path: '/action-plan',
          builder: (_, _) => const Scaffold(body: Text('Action plan')),
        ),
        for (final path in ['/', '/learn', '/profile'])
          GoRoute(
            path: path,
            builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
          ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: buildTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('capture pixel reference monitoring screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpMonitoring(tester);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('screenshots/monitoring-390x844.png'),
    );
  });

  testWidgets('capture pixel reference red zone popup', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpMonitoring(tester);
    final context = tester.element(find.byType(Scaffold));
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .58),
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
        child: const PeakFlowResultDialog(
          assessment: PeakFlowAssessment(
            readings: [900, 600, 800],
            highest: 900,
            personalBest: 13234,
            percentage: 6.8,
            zone: PeakFlowZone.red,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile('screenshots/pef-red-popup-390x844.png'),
    );
  });
}
