import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-2 — TEST DE ORO de detección de marca. Contrato de aceptación de los
/// escenarios 8.1 (nombres reales), 8.2 (anti-falso-positivo) y 8.3
/// (normalización). Cualquier marca nueva con alias corto DEBE pasar esta suite
/// antes de mergearse (red de seguridad de R1).
void main() {
  group('8.1 [auto] nombres reales -> id esperado', () {
    final cases = <String, String>{
      'Davivienda': 'davivienda',
      'Cuenta Daviplata': 'daviplata', // NO davivienda (especificidad)
      'DaviPlata': 'daviplata',
      'Mi Nequi': 'nequi',
      'Nubank': 'nubank',
      'nu': 'nubank', // exact
      'PayPal': 'paypal',
      'paypal personal': 'paypal',
      'MercadoPago': 'mercadopago',
      'Mercado Pago': 'mercadopago',
      'Global66': 'global66',
      'PayU': 'payu',
      'ARQ a la mano': 'arq',
      'Pibank': 'pibank',
      'Trii': 'trii',
      'DolarApp': 'dolarapp',
    };

    cases.forEach((input, expectedId) {
      test("'$input' -> $expectedId", () {
        final brand = detectBrand(input);
        expect(brand, isNotNull, reason: "'$input' debería detectar marca");
        expect(brand!.id, expectedId);
      });
    });
  });

  group('8.2 [auto] anti-falso-positivo -> null', () {
    final negatives = <String>[
      'mipaypalito', // paypal NO matchea dentro (word)
      'marqueta', // arq NO matchea dentro (word)
      'menu', // nu NO matchea dentro (exact)
      'banco x raro',
      'mi banco desconocido',
    ];

    for (final input in negatives) {
      test("'$input' -> null", () {
        expect(detectBrand(input), isNull,
            reason: "'$input' NO debería detectar ninguna marca");
      });
    }
  });

  group('8.3 [auto] normalización (acentos / mayúsculas / separadores)', () {
    final bancolombiaVariants = <String>[
      'Bancolómbia',
      'BANCOLOMBIA',
      'bancolombia',
      'Bancolombia',
    ];

    for (final input in bancolombiaVariants) {
      test("'$input' -> bancolombia", () {
        final brand = detectBrand(input);
        expect(brand, isNotNull);
        expect(brand!.id, 'bancolombia');
      });
    }

    test("normalizeBrandText('Bancolómbia') == 'bancolombia'", () {
      expect(normalizeBrandText('Bancolómbia'), 'bancolombia');
    });

    test('normalizeBrandText colapsa separadores -_. y espacios', () {
      expect(normalizeBrandText('Mercado-Pago'), 'mercado pago');
      expect(normalizeBrandText('mercado_pago'), 'mercado pago');
      expect(normalizeBrandText('  Mi   Nequi  '), 'mi nequi');
    });
  });

  group('borde: nombre vacío -> null', () {
    test("'' -> null", () => expect(detectBrand(''), isNull));
    test("'   ' -> null", () => expect(detectBrand('   '), isNull));
  });
}
