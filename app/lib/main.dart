import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(
    // Inject Riverpod ProviderScope at the root of the app
    const ProviderScope(
      child: MeenAlTheebApp(),
    ),
  );
}

class MeenAlTheebApp extends ConsumerWidget {
  const MeenAlTheebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
