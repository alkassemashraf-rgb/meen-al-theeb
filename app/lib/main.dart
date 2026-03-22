import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'firebase_options.dart';
import 'services/deep_link/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch and log Flutter framework errors (visible in flutter run console)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init error: $e\n$st');
  }

  runApp(
    const ProviderScope(
      child: MeenAlTheebApp(),
    ),
  );
}

class MeenAlTheebApp extends ConsumerStatefulWidget {
  const MeenAlTheebApp({super.key});

  @override
  ConsumerState<MeenAlTheebApp> createState() => _MeenAlTheebAppState();
}

class _MeenAlTheebAppState extends ConsumerState<MeenAlTheebApp> {
  @override
  void initState() {
    super.initState();
    // Eagerly initialize so cold-start deep links are captured
    // before SplashScreen navigates to /home.
    ref.read(deepLinkServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Meen Al Theeb?',
      theme: AppTheme.lightTheme,

      // Routing Shell
      routerConfig: appRouter,

      // Localization Setups
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic (Default RTL)
        Locale('en', ''), // English
      ],
      // Force Arabic as default locale for the MVP
      locale: const Locale('ar', ''),

      debugShowCheckedModeBanner: false,
    );
  }
}
