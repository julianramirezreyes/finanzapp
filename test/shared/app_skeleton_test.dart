import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_skeleton.dart';
import 'package:finanzapp_v2/shared/ui/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario 6b.2 [auto] — AppSkeleton bajo darkTheme usa superficie oscura
/// (helper `surface(dark)` == surfaceDark) y NUNCA un pastel claro. El shimmer
/// que compone ya es brightness-aware (surfaceVariantDark/surfaceDark en dark),
/// pero el contenedor de la tile (SkeletonTile) debe pintar la superficie del
/// tema, no un literal claro. Tabla-driven por brillo.
void main() {
  /// Devuelve el `Color` de fondo de la primera tile renderizada por un
  /// SkeletonList bajo el brillo indicado. La tile envuelve su contenido en un
  /// AppCard (DecoratedBox) cuyo color resuelve `context.surface`.
  Future<Color?> tileSurfaceFor(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme,
        home: const Scaffold(body: SkeletonList(itemCount: 1)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final tileFinder = find.byKey(const ValueKey('skeleton-tile-surface'));
    expect(tileFinder, findsOneWidget);
    final box = tester.widget<DecoratedBox>(tileFinder);
    return (box.decoration as BoxDecoration).color;
  }

  group('6b.2 AppSkeleton brightness-aware', () {
    testWidgets('SkeletonTile usa surfaceDark en dark (no pastel claro)', (
      tester,
    ) async {
      final color = await tileSurfaceFor(tester, Brightness.dark);
      expect(color, AppColors.surfaceDark);
      // Guardrail: jamás un literal claro chillón en dark.
      expect(color, isNot(AppColors.surfaceLight));
      expect(color, isNot(AppColors.backgroundLight));
    });

    testWidgets('SkeletonTile usa surfaceLight en light (triangulación)', (
      tester,
    ) async {
      final color = await tileSurfaceFor(tester, Brightness.light);
      expect(color, AppColors.surfaceLight);
    });

    testWidgets('SkeletonList renderiza itemCount tiles con shimmer animado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SkeletonList(itemCount: 3)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonTile), findsNWidgets(3));
      // El shimmer real (ShimmerLoading animado) está presente dentro.
      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('AppSkeleton.circle es redondo (BoxShape.circle)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSkeleton(
              variant: SkeletonVariant.circle,
              size: 40,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppSkeleton), findsOneWidget);
      // Un círculo se construye como ShimmerLoading con borderRadius == size/2.
      final shimmer = tester.widget<ShimmerLoading>(
        find.byType(ShimmerLoading),
      );
      expect(shimmer.borderRadius, 20);
      expect(shimmer.width, 40);
      expect(shimmer.height, 40);
    });
  });
}
