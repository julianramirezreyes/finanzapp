import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-3 — fallback para entidades desconocidas. Escenario 8.4 [auto]: mismo
/// nombre -> mismo color (estable, no aleatorio) + monograma elegante.
void main() {
  group('8.4 [auto] fallbackColorFor es estable', () {
    test('mismo nombre -> mismo color en llamadas repetidas', () {
      expect(fallbackColorFor('Banco Raro'), fallbackColorFor('Banco Raro'));
    });

    test('case/trim-insensitive (trim().toLowerCase())', () {
      expect(fallbackColorFor('banco raro'), fallbackColorFor('Banco Raro'));
      expect(fallbackColorFor('  Banco Raro  '), fallbackColorFor('Banco Raro'));
    });

    test('el color pertenece a la paleta curada', () {
      expect(kFallbackPalette.length, 9);
      expect(kFallbackPalette.contains(fallbackColorFor('Banco Raro')), isTrue);
      expect(kFallbackPalette.contains(fallbackColorFor('Otra Cosa X')), isTrue);
    });

    test('color es un Color válido', () {
      expect(fallbackColorFor('cualquiera'), isA<Color>());
    });
  });

  group('monogramFor', () {
    test('2+ palabras -> iniciales en mayúscula', () {
      expect(monogramFor('Mi Nequi'), 'MN');
      expect(monogramFor('banco de bogota'), 'BD');
    });

    test('1 palabra -> 2 primeras letras en mayúscula', () {
      expect(monogramFor('Bancolombia'), 'BA');
      expect(monogramFor('nu'), 'NU');
    });

    test('1 letra -> esa letra', () {
      expect(monogramFor('x'), 'X');
    });

    test('vacío -> ?', () {
      expect(monogramFor(''), '?');
      expect(monogramFor('   '), '?');
    });
  });
}
