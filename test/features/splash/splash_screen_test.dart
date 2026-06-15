import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/splash/domain/splash_state.dart';
import 'package:finanzapp_v2/features/splash/presentation/splash_health_notifier.dart';
import 'package:finanzapp_v2/features/splash/presentation/splash_screen.dart';
import 'package:finanzapp_v2/shared/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Escenarios 7.1, 7.2, 7.3, 7.5 [auto].
///
/// CONVENCIÓN CRÍTICA: el splash usa AnimationControllers con `.repeat()`
/// (_pulse) y el ScannerProgress también — en estados NO terminales SIEMPRE
/// `pump(Duration)`, NUNCA `pumpAndSettle` (colgaría). En el estado `ready` el
/// splash navega y se desmonta, por lo que ahí sí se puede settle.

/// Notifier fake controlable que NO arranca timers reales (startPolling no-op),
/// permitiendo testear cada estado de forma aislada y emitir `ready` a demanda.
///
/// Extiende [SplashHealthNotifier] para satisfacer la firma tipada de
/// `splashHealthProvider.overrideWith`, pero sobreescribe `build`/`startPolling`
/// /`retry` para no tocar dio/dashboard/timers reales.
class _FakeSplashNotifier extends SplashHealthNotifier {
  _FakeSplashNotifier(this._initial);

  final SplashState _initial;
  int retryCalls = 0;

  @override
  SplashState build() => _initial;

  void emit(SplashState next) => state = next;

  // El splash llama startPolling() en postFrameCallback: no-op para no crear
  // Timers reales (que colgarían el test).
  @override
  void startPolling() {}

  @override
  void retry() {
    retryCalls++;
  }
}

/// SupabaseClient liviano con credenciales dummy: `auth.currentSession` es null
/// sin tocar la red -> fuerza la ruta '/login'. Evita depender de
/// `Supabase.instance` (no inicializado en tests).
///
/// `autoRefreshToken: false` desactiva el `Timer.periodic` de refresco de sesión
/// del GoTrueClient; de lo contrario quedaría un timer colgando al desmontar el
/// árbol y el test fallaría con "A Timer is still pending".
SupabaseClient _fakeSupabase() => SupabaseClient(
  'http://localhost',
  'anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

void main() {
  late _FakeSplashNotifier notifier;

  ProviderScope hostWithRouter({
    required SplashState initial,
    required GoRouter router,
    SupabaseClient? supabase,
  }) {
    notifier = _FakeSplashNotifier(initial);
    return ProviderScope(
      overrides: [
        splashHealthProvider.overrideWith(() => notifier),
        if (supabase != null)
          supabaseClientProvider.overrideWithValue(supabase),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  Widget hostSimple({
    required SplashState initial,
    required ThemeData theme,
  }) {
    notifier = _FakeSplashNotifier(initial);
    return ProviderScope(
      overrides: [splashHealthProvider.overrideWith(() => notifier)],
      child: MaterialApp(theme: theme, home: const SplashScreen()),
    );
  }

  testWidgets(
    '7.1 connecting muestra BrandMark + ScannerProgress (no el indicador viejo)',
    (tester) async {
      await tester.pumpWidget(
        hostSimple(initial: SplashState.connecting, theme: AppTheme.lightTheme),
      );
      // .repeat() nunca settle-a: pump con duración, NO pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(BrandMark), findsOneWidget);
      expect(find.byType(ScannerProgress), findsOneWidget);
      expect(find.text('FinanzApp'), findsOneWidget);
    },
  );

  testWidgets(
    '7.2 error muestra Reintentar y al tocarlo llama notifier.retry()',
    (tester) async {
      await tester.pumpWidget(
        hostSimple(initial: SplashState.error, theme: AppTheme.lightTheme),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reintentar'), findsOneWidget);
      expect(notifier.retryCalls, 0);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(notifier.retryCalls, 1);
    },
  );

  testWidgets(
    '7.2 error usa AppColors.expense (correcto en dark, no color claro)',
    (tester) async {
      await tester.pumpWidget(
        hostSimple(initial: SplashState.error, theme: AppTheme.darkTheme),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Sin conexión con el servidor'),
      );
      expect(paragraph.text.style?.color, AppColors.expense);
    },
  );

  testWidgets(
    '7.3 al pasar a ready navega a /login (sin sesión) una sola vez',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('LOGIN'))),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('HOME'))),
          ),
        ],
      );

      await tester.pumpWidget(
        hostWithRouter(
          initial: SplashState.connecting,
          router: router,
          supabase: _fakeSupabase(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('LOGIN'), findsNothing);

      // Emitir ready DOS veces: el guard _leaving debe evitar doble navegación.
      notifier.emit(SplashState.ready);
      await tester.pump();
      notifier.emit(SplashState.ready);
      // El _exit (420ms) sí settle-a: tras navegar el splash se desmonta y los
      // tickers .repeat() dejan de correr.
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '7.5 wordmark FinanzApp != textPrimary claro bajo darkTheme',
    (tester) async {
      await tester.pumpWidget(
        hostSimple(initial: SplashState.connecting, theme: AppTheme.darkTheme),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('FinanzApp'),
      );
      // onSurface en dark es claro (legible); lo que NO debe ser es el texto
      // oscuro hardcodeado del boceto literal (AppColors.textPrimary), que
      // sería invisible sobre el fondo oscuro.
      expect(paragraph.text.style?.color, isNot(AppColors.textPrimary));
    },
  );
}
