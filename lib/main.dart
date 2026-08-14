import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'routes/app_router.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Startup service error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  await AppState.instance.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AsthmaCareApp());
}

class AsthmaCareApp extends StatelessWidget {
  const AsthmaCareApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (_, child) => MaterialApp.router(
      key: ValueKey(AppState.instance.arabic),
      debugShowCheckedModeBanner: false,
      title: 'Asthma Care!',
      theme: buildTheme(),
      locale: Locale(AppState.instance.arabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) => Directionality(
        textDirection: AppState.instance.arabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
    ),
  );
}
