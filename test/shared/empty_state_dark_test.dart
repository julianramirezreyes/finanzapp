import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario 6a.4 — el título de EmptyState debe ser legible en dark.
/// Antes pisaba el color con `.copyWith(color: AppColors.textPrimary)` (oscuro),
/// haciéndolo INVISIBLE sobre el fondo oscuro. Tras el fix hereda onSurface.
void main() {
  testWidgets('título de EmptyState != textPrimary claro bajo darkTheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: EmptyState(icon: Icons.inbox, title: 'Vacío'),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('Vacío'));
    final color = paragraph.text.style?.color;

    expect(color, isNot(AppColors.textPrimary));
  });
}
