import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WU-La1 — escenario L.2 [auto]: los 13 logos están bundleados en
/// `assets/brands/<id>.<ext>` y el pubspec declara `assets/brands/`.
///
/// Anclado a la lista LITERAL de 13 paths esperados (no depende de que
/// `kBankBrands.asset` ya esté poblado), para poder correrse aislado.
void main() {
  // 11 SVG + 2 PNG (global66, payu).
  const expectedAssets = <String>[
    'assets/brands/bancolombia.svg',
    'assets/brands/davivienda.svg',
    'assets/brands/nequi.svg',
    'assets/brands/daviplata.svg',
    'assets/brands/nubank.svg',
    'assets/brands/pibank.svg',
    'assets/brands/trii.svg',
    'assets/brands/dolarapp.svg',
    'assets/brands/mercadopago.svg',
    'assets/brands/paypal.svg',
    'assets/brands/arq.svg',
    'assets/brands/global66.png',
    'assets/brands/payu.png',
  ];

  group('L.2 [auto] assets de marca bundleados', () {
    test('los 13 archivos existen en disco', () {
      for (final path in expectedAssets) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'falta el asset $path',
        );
      }
    });

    test('pubspec declara flutter_svg y la carpeta assets/brands/', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        RegExp(r'^\s*flutter_svg:', multiLine: true).hasMatch(pubspec),
        isTrue,
        reason: 'pubspec.yaml debe declarar flutter_svg en dependencies',
      );
      expect(
        RegExp(r'^\s*-\s*assets/brands/', multiLine: true).hasMatch(pubspec),
        isTrue,
        reason: 'pubspec.yaml debe declarar - assets/brands/ en flutter.assets',
      );
    });
  });
}
