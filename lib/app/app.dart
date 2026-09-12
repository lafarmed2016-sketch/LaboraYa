import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/app/router/app_router.dart';
import 'package:laboraya_app/app/theme/app_theme.dart';
import 'package:laboraya_app/core/services/push_notification_service.dart';

class LaboraYaApp extends ConsumerStatefulWidget {
  const LaboraYaApp({super.key});

  @override
  ConsumerState<LaboraYaApp> createState() => _LaboraYaAppState();
}

class _LaboraYaAppState extends ConsumerState<LaboraYaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      ref.read(pushNotificationServiceProvider).initialize(router);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LaboraYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
