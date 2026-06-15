import 'package:finanzapp_v2/core/config/supabase_config.dart';
import 'package:finanzapp_v2/core/auth/session_invalidator.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/core/theme/theme_mode_provider.dart';
import 'package:finanzapp_v2/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await initializeDateFormatting('es_CO', null);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Eager-init the sign-out invalidation listener so it lives for the whole
    // session. On AuthChangeEvent.signedOut it invalidates every user-data
    // provider, preventing the next user from seeing the previous user's cached
    // data (spec 2c.1 / 2c.2). Returns void — watching it only primes the listener.
    ref.watch(sessionInvalidatorProvider);

    return MaterialApp.router(
      title: 'FinanzApp v2',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO'), Locale('en', 'US')],
      locale: const Locale('es', 'CO'),
    );
  }
}
