import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/shared/ui/widgets/branded_vault_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// branded-vault-header [auto]: HERO HEADER de marca para la pantalla de bóveda
/// ("header como tarjeta"). Banda con gradiente de marca, esquinas inferiores
/// redondeadas, logo limpio en chip + nombre/subtítulo/total grandes, watermark
/// tenue a la derecha y back arrow.
///
/// Contrato clave: el color del texto onBrand es ADAPTATIVO por luminancia del
/// color base — sobre Bancolombia (amarillo claro) el texto es OSCURO
/// (AppColors.textPrimary); sobre Nubank (morado oscuro) el texto es BLANCO.
/// Para marca desconocida degrada con el color de fallback sin romper.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget header, {
    required Brightness brightness,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light(),
        home: Scaffold(body: header),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// Recorre el árbol de Text bajo [headerFinder] y devuelve true si ALGUNO
  /// resuelve su color efectivo a [expected] (estilo propio o heredado del
  /// DefaultTextStyle más cercano).
  bool anyTextHasColor(WidgetTester tester, Finder textFinder, Color expected) {
    final texts = tester.widgetList<Text>(textFinder);
    for (final t in texts) {
      final element = tester.element(find.byWidget(t));
      final resolved =
          t.style?.color ?? DefaultTextStyle.of(element).style.color;
      if (resolved == expected) return true;
    }
    return false;
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final label = brightness == Brightness.dark ? 'dark' : 'light';

    group('[auto] BrandedVaultHeader en $label', () {
      testWidgets(
          'marca CLARA (Bancolombia): texto OSCURO sobre el gradiente '
          'amarillo; renderiza name/subtitle/total/back sin throw',
          (tester) async {
        var backTapped = false;
        await pump(
          tester,
          BrandedVaultHeader(
            name: 'Bancolombia',
            subtitle: 'Bóveda · Ahorros',
            total: r'$ 2.217.827',
            onBack: () => backTapped = true,
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // Contenido textual presente.
        expect(find.text('Bancolombia'), findsOneWidget);
        expect(find.text('Bóveda · Ahorros'), findsOneWidget);
        expect(find.text(r'$ 2.217.827'), findsOneWidget);

        // Banda tipo tarjeta: hay un ClipRRect (esquinas redondeadas) y un
        // gradiente de fondo.
        expect(find.byType(ClipRRect), findsWidgets);
        final hasGradient = tester
            .widgetList<Container>(find.byType(Container))
            .any((c) {
          final dec = c.decoration;
          return dec is BoxDecoration && dec.gradient is LinearGradient;
        });
        expect(hasGradient, isTrue, reason: 'falta el gradiente de marca');

        // Texto onBrand OSCURO: el nombre usa AppColors.textPrimary porque el
        // amarillo de Bancolombia tiene luminancia alta.
        expect(
          anyTextHasColor(
            tester,
            find.text('Bancolombia'),
            AppColors.textPrimary,
          ),
          isTrue,
          reason: 'el nombre debe ser texto OSCURO sobre amarillo',
        );

        // Back arrow funcional.
        final backIcon = find.byIcon(Icons.arrow_back_ios_new);
        expect(backIcon, findsOneWidget);
        await tester.tap(backIcon);
        expect(backTapped, isTrue);
      });

      testWidgets(
          'marca OSCURA (Nubank): texto BLANCO sobre el gradiente morado',
          (tester) async {
        await pump(
          tester,
          BrandedVaultHeader(
            name: 'Nubank',
            subtitle: 'Bóveda · Crédito',
            total: r'-$ 540.000',
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Nubank'), findsOneWidget);
        expect(find.text(r'-$ 540.000'), findsOneWidget);

        // Texto onBrand BLANCO: el morado de Nubank tiene luminancia baja.
        expect(
          anyTextHasColor(tester, find.text('Nubank'), Colors.white),
          isTrue,
          reason: 'el nombre debe ser texto BLANCO sobre morado',
        );
      });

      testWidgets('marca DESCONOCIDA (Banco Raro): degrada con fallback',
          (tester) async {
        await pump(
          tester,
          const BrandedVaultHeader(
            name: 'Banco Raro',
            subtitle: 'Bóveda',
            total: r'$ 100.000',
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Banco Raro'), findsOneWidget);
        expect(find.text(r'$ 100.000'), findsOneWidget);

        // Sigue habiendo un gradiente (derivado del color de fallback).
        final hasGradient = tester
            .widgetList<Container>(find.byType(Container))
            .any((c) {
          final dec = c.decoration;
          return dec is BoxDecoration && dec.gradient is LinearGradient;
        });
        expect(hasGradient, isTrue, reason: 'falta el gradiente de fallback');
      });

      testWidgets('sin total ni onBack: renderiza solo name/subtitle sin throw',
          (tester) async {
        await pump(
          tester,
          const BrandedVaultHeader(name: 'Nequi', subtitle: 'Bóveda'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Nequi'), findsOneWidget);
        // Sin onBack no se exige un back arrow.
        expect(find.text('Bóveda'), findsOneWidget);
      });
    });
  }
}
