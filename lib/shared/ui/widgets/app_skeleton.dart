import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'loading_indicator.dart';

/// Forma del placeholder de carga.
enum SkeletonVariant {
  /// Línea de texto (alto bajo, ancho flexible).
  line,

  /// Bloque rectangular (imagen/tarjeta).
  box,

  /// Círculo (avatar/icono).
  circle,
}

/// Placeholder de carga brightness-aware (SDD #6, slice 6b).
///
/// Compone [ShimmerLoading] (ya brightness-aware: gris elevado en dark, NUNCA
/// pastel claro) en tres variantes reutilizables. Reemplaza los
/// `CircularProgressIndicator` crudos por un loading consistente con el design
/// system.
class AppSkeleton extends StatelessWidget {
  final SkeletonVariant variant;

  /// Para [SkeletonVariant.circle]: diámetro. Ignorado en otras variantes.
  final double size;

  /// Ancho del placeholder (line/box). `double.infinity` por defecto en line.
  final double? width;

  /// Alto del placeholder (line/box).
  final double height;

  const AppSkeleton({
    super.key,
    this.variant = SkeletonVariant.line,
    this.size = 40,
    this.width,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SkeletonVariant.circle:
        return ShimmerLoading(
          width: size,
          height: size,
          borderRadius: size / 2,
        );
      case SkeletonVariant.box:
        return ShimmerLoading(
          width: width ?? double.infinity,
          height: height,
          borderRadius: AppSpacing.buttonRadius,
        );
      case SkeletonVariant.line:
        return ShimmerLoading(
          width: width ?? double.infinity,
          height: height,
          borderRadius: 4,
        );
    }
  }
}

/// Una fila de placeholder con la silueta de una tile (icono + dos líneas +
/// monto), envuelta en la superficie del tema vía [AppCard].
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    // El fondo de la tile resuelve la superficie del tema (surfaceDark en dark,
    // surfaceLight en light) — NUNCA un pastel claro. Se expone un DecoratedBox
    // con key estable para poder verificar el color en test.
    return DecoratedBox(
      key: const ValueKey('skeleton-tile-surface'),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const AppSkeleton(variant: SkeletonVariant.circle, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton(variant: SkeletonVariant.line, width: 140),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(variant: SkeletonVariant.line, width: 80),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const AppSkeleton(
              variant: SkeletonVariant.box,
              width: 64,
              height: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista vertical de [SkeletonTile] para estados de carga de listas/dashboards.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const SkeletonTile(),
    );
  }
}
