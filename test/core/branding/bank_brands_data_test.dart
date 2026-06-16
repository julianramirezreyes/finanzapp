import 'package:finanzapp_v2/core/branding/bank_brand.dart';
import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-La2 — escenario L.1 [auto]: las 13 entradas con marca de [kBankBrands]
/// declaran su `asset` apuntando a `assets/brands/<id>.<ext>` (svg salvo
/// global66/payu = png) y los 4 colores erróneos quedaron corregidos.
void main() {
  BankBrand brandById(String id) =>
      kBankBrands.firstWhere((b) => b.id == id);

  group('L.1 [auto] asset poblado por marca', () {
    // id -> extensión esperada.
    const expectedExt = <String, String>{
      'bancolombia': 'svg',
      'davivienda': 'svg',
      'nequi': 'svg',
      'daviplata': 'svg',
      'nubank': 'svg',
      'pibank': 'svg',
      'trii': 'svg',
      'dolarapp': 'svg',
      'mercadopago': 'svg',
      'paypal': 'svg',
      'arq': 'svg',
      'global66': 'png',
      'payu': 'png',
    };

    expectedExt.forEach((id, ext) {
      test("$id -> assets/brands/$id.$ext", () {
        final brand = brandById(id);
        expect(brand.asset, isNotNull, reason: '$id debe tener asset');
        expect(brand.asset, 'assets/brands/$id.$ext');
      });
    });

    test('las 13 marcas con asset están cubiertas', () {
      final withAsset = kBankBrands.where((b) => b.asset != null).length;
      expect(withAsset, 13);
    });
  });

  group('L.1 [auto] colores corregidos', () {
    test('global66 primary es azul 0xFF2745C7', () {
      expect(brandById('global66').primary, const Color(0xFF2745C7));
    });

    test('trii primary es verde 0xFF02FB7E', () {
      expect(brandById('trii').primary, const Color(0xFF02FB7E));
    });

    test('pibank primary es amarillo 0xFFFFDC00', () {
      expect(brandById('pibank').primary, const Color(0xFFFFDC00));
    });

    test('arq primary es negro 0xFF000000', () {
      expect(brandById('arq').primary, const Color(0xFF000000));
    });
  });
}
