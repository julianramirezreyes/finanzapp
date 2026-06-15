import 'package:finanzapp_v2/core/branding/bank_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-1 (soporte de 8.5) — value object [BankBrand], su [gradient] y el
/// helper interno de oscurecido. Lógica pura, sin render.
void main() {
  group('MatchKind / BrandMatcher', () {
    test('MatchKind expone exact, word y contains', () {
      expect(MatchKind.values, containsAll(<MatchKind>[
        MatchKind.exact,
        MatchKind.word,
        MatchKind.contains,
      ]));
      expect(MatchKind.values.length, 3);
    });

    test('BrandMatcher por defecto usa MatchKind.word', () {
      const m = BrandMatcher('x');
      expect(m.kind, MatchKind.word);
      expect(m.alias, 'x');
    });

    test('BrandMatcher acepta kind explícito', () {
      const m = BrandMatcher('nu', MatchKind.exact);
      expect(m.kind, MatchKind.exact);
    });
  });

  group('BankBrand.gradient', () {
    test('con secondary != null usa [primary, secondary]', () {
      const primary = Color(0xFFDA0081);
      const secondary = Color(0xFF20104A);
      const brand = BankBrand(
        id: 'nequi',
        displayName: 'Nequi',
        primary: primary,
        secondary: secondary,
        accent: Color(0xFFB80070),
        matchers: [BrandMatcher('nequi')],
      );

      final g = brand.gradient;
      expect(g, isA<LinearGradient>());
      expect(g.colors, [primary, secondary]);
    });

    test('sin secondary oscurece primary (lightness menor) -> _darken', () {
      const primary = Color(0xFF10B981);
      const brand = BankBrand(
        id: 'x',
        displayName: 'X',
        primary: primary,
        accent: primary,
        matchers: [BrandMatcher('x')],
      );

      final g = brand.gradient;
      expect(g.colors.first, primary);
      final darkened = g.colors[1];
      expect(
        HSLColor.fromColor(darkened).lightness,
        lessThan(HSLColor.fromColor(primary).lightness),
      );
    });
  });
}
