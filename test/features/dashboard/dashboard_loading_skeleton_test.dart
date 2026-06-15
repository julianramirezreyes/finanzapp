import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario 6b.1 [auto] — el estado de carga del dashboard muestra el
/// AppSkeleton (vía SkeletonList) y NO un CircularProgressIndicator crudo.
///
/// El loading state se extrajo a [DashboardLoadingView] (Extract-Before-Mock):
/// montar el DashboardScreen completo exigiría 7+ overrides de providers y el
/// AppDrawer con sus dependencias, lo que violaría la higiene de mocks. El
/// loading es un widget puro sin providers, así que se testea en aislamiento.
void main() {
  Future<void> pumpLoading(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: DashboardLoadingView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('dashboard loading muestra SkeletonList, no CircularProgress', (
    tester,
  ) async {
    await pumpLoading(tester, AppTheme.lightTheme);

    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('dashboard loading en dark también usa skeleton (no progress)', (
    tester,
  ) async {
    await pumpLoading(tester, AppTheme.darkTheme);

    expect(find.byType(SkeletonTile), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
