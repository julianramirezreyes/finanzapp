import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario 6a.2 — guardrail no-hardcoded-color.
/// Los getters NO-semánticos de AppTypography NO deben fijar `color`: deben
/// heredar `onSurface` del tema (claro en light, blanco en dark). Si un getter
/// fija textPrimary (oscuro), el texto es INVISIBLE en dark mode.
/// Los getters SEMÁNTICOS (income/expense) y los SECUNDARIOS DELIBERADOS
/// (bodySmall/labelMedium en textSecondary, labelSmall en textMuted) SÍ
/// conservan su color como jerarquía de énfasis declarada.
///
/// NOTA: los getters invocan GoogleFonts.inter, que dispara carga de assets, por
/// lo que NO deben llamarse en la fase de declaración de grupos (binding aún no
/// inicializado). Se invocan dentro de cada test/testWidgets.
void main() {
  group('6a.2 AppTypography no-semánticos no fijan color', () {
    // Los 16 getters que deben heredar onSurface (color == null).
    final nonSemantic = <String, TextStyle Function()>{
      'displayLarge': () => AppTypography.displayLarge,
      'displayMedium': () => AppTypography.displayMedium,
      'displaySmall': () => AppTypography.displaySmall,
      'headlineLarge': () => AppTypography.headlineLarge,
      'headlineMedium': () => AppTypography.headlineMedium,
      'headlineSmall': () => AppTypography.headlineSmall,
      'titleLarge': () => AppTypography.titleLarge,
      'titleMedium': () => AppTypography.titleMedium,
      'titleSmall': () => AppTypography.titleSmall,
      'bodyLarge': () => AppTypography.bodyLarge,
      'bodyMedium': () => AppTypography.bodyMedium,
      'labelLarge': () => AppTypography.labelLarge,
      'balance': () => AppTypography.balance,
      'balanceSmall': () => AppTypography.balanceSmall,
      'amount': () => AppTypography.amount,
      'amountSmall': () => AppTypography.amountSmall,
    };

    for (final entry in nonSemantic.entries) {
      testWidgets('${entry.key}.color es null (hereda onSurface)', (
        tester,
      ) async {
        expect(
          entry.value().color,
          isNull,
          reason:
              '${entry.key} no debe fijar color; debe heredar onSurface del tema',
        );
      });
    }

    testWidgets('income/expense conservan su color semántico', (tester) async {
      expect(AppTypography.income.color, AppColors.income);
      expect(AppTypography.expense.color, AppColors.expense);
    });

    testWidgets('secundarios deliberados conservan su color de jerarquía', (
      tester,
    ) async {
      expect(AppTypography.bodySmall.color, AppColors.textSecondary);
      expect(AppTypography.labelMedium.color, AppColors.textSecondary);
      expect(AppTypography.labelSmall.color, AppColors.textMuted);
    });
  });

  group('6a.1 getters no-semánticos resuelven color legible bajo darkTheme', () {
    Future<Color?> resolvedColor(
      WidgetTester tester,
      TextStyle style,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: Text('x', style: style)),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text('x'));
      return paragraph.text.style?.color;
    }

    testWidgets('titleSmall != textPrimary claro bajo darkTheme', (
      tester,
    ) async {
      final c = await resolvedColor(tester, AppTypography.titleSmall);
      expect(c, isNot(AppColors.textPrimary));
    });

    testWidgets('bodyLarge != textPrimary claro bajo darkTheme', (
      tester,
    ) async {
      final c = await resolvedColor(tester, AppTypography.bodyLarge);
      expect(c, isNot(AppColors.textPrimary));
    });

    testWidgets('balance != textPrimary claro bajo darkTheme', (tester) async {
      final c = await resolvedColor(tester, AppTypography.balance);
      expect(c, isNot(AppColors.textPrimary));
    });
  });
}
