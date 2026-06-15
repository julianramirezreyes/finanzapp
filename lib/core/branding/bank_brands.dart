import 'package:flutter/material.dart';
import 'bank_brand.dart';

/// Tabla const de marcas, ORDENADA POR ESPECIFICIDAD: una marca propia siempre
/// va ANTES que su familia (DaviPlata antes que Davivienda) para que el primer
/// match sea el correcto.
///
/// Agregar un banco nuevo = una línea de datos aquí. Tras agregarlo, correr el
/// TEST DE ORO (`detect_brand_test.dart`) — los alias cortos son frágiles.
///
/// Los hex son aproximados de identidad pública (D9): validar antes de
/// producción. `accent` se separa de `primary` cuando el principal no contrasta
/// sobre superficie clara (ej. amarillo Bancolombia, negros DolarApp/Trii).
const List<BankBrand> kBankBrands = [
  // --- DaviPlata ANTES que Davivienda (marca propia) ---
  BankBrand(
    id: 'daviplata',
    displayName: 'DaviPlata',
    primary: Color(0xFFED1C24),
    accent: Color(0xFFC4161C),
    matchers: [BrandMatcher('daviplata')], // word
  ),
  BankBrand(
    id: 'davivienda',
    displayName: 'Davivienda',
    primary: Color(0xFFED1C24),
    accent: Color(0xFFC4161C),
    matchers: [BrandMatcher('davivienda', MatchKind.contains)],
  ),
  BankBrand(
    id: 'bancolombia',
    displayName: 'Bancolombia',
    primary: Color(0xFFFFD200),
    secondary: Color(0xFFFFC107),
    accent: Color(0xFF8A6D00), // amarillo no contrasta -> accent oscuro
    matchers: [BrandMatcher('bancolombia', MatchKind.contains)],
  ),
  BankBrand(
    id: 'nequi',
    displayName: 'Nequi',
    primary: Color(0xFFDA0081),
    secondary: Color(0xFF20104A),
    accent: Color(0xFFB80070),
    matchers: [BrandMatcher('nequi')], // word
  ),
  BankBrand(
    id: 'nubank',
    displayName: 'Nubank',
    primary: Color(0xFF820AD1),
    accent: Color(0xFF820AD1),
    matchers: [
      BrandMatcher('nubank', MatchKind.contains),
      BrandMatcher('nu', MatchKind.exact), // 'nu' SOLO exacto (nunca en 'menu')
    ],
  ),
  BankBrand(
    id: 'pibank',
    displayName: 'Pibank',
    primary: Color(0xFF00C46A),
    accent: Color(0xFF009E55),
    matchers: [BrandMatcher('pibank', MatchKind.contains)],
  ),
  BankBrand(
    id: 'trii',
    displayName: 'Trii',
    primary: Color(0xFF1B1B3A),
    accent: Color(0xFF1B1B3A),
    matchers: [BrandMatcher('trii')], // word
  ),
  // CORRECCIÓN al boceto (D3): PayPal = MatchKind.word (NO contains). 'contains'
  // rompería 8.2 ('paypal' dentro de 'mipaypalito'). El contrato es el escenario.
  BankBrand(
    id: 'paypal',
    displayName: 'PayPal',
    primary: Color(0xFF003087),
    secondary: Color(0xFF0070BA),
    accent: Color(0xFF003087),
    matchers: [BrandMatcher('paypal')], // word
  ),
  BankBrand(
    id: 'mercadopago',
    displayName: 'Mercado Pago',
    primary: Color(0xFF009EE3),
    accent: Color(0xFF007EB5),
    matchers: [
      BrandMatcher('mercadopago', MatchKind.contains), // 'MercadoPago' pegado
      BrandMatcher('mercado pago', MatchKind.contains), // ya normalizado
    ],
  ),
  BankBrand(
    id: 'dolarapp',
    displayName: 'DolarApp',
    primary: Color(0xFF111111),
    accent: Color(0xFF111111),
    matchers: [BrandMatcher('dolarapp', MatchKind.contains)],
  ),
  BankBrand(
    id: 'arq',
    displayName: 'A la Mano (ARQ)',
    primary: Color(0xFFED1C24),
    accent: Color(0xFFC4161C),
    matchers: [
      BrandMatcher('arq'), // word (no matchea 'marqueta')
      BrandMatcher('a la mano', MatchKind.contains),
    ],
  ),
  BankBrand(
    id: 'global66',
    displayName: 'Global66',
    primary: Color(0xFF2DCE89),
    accent: Color(0xFF1FA56C),
    matchers: [BrandMatcher('global66', MatchKind.contains)],
  ),
  BankBrand(
    id: 'payu',
    displayName: 'PayU',
    primary: Color(0xFFA6C307),
    accent: Color(0xFF7E9400),
    matchers: [BrandMatcher('payu')], // word
  ),
  // --- Extensible: agregar entidades nuevas como una línea de datos arriba ---
  // BancoDeBogota, BBVA, Scotiabank Colpatria, Lulo, RappiPay, Ualá, Wise...
];

/// Normaliza un nombre para comparación: minúsculas + sin acentos (sustitución
/// por tabla NFD-like) + separadores `[\s\-_.]+` colapsados a un solo espacio.
///
/// Garantiza que 'Bancolómbia' / 'BANCOLOMBIA' / 'banco_lombia'? colapsen de
/// forma estable (escenario 8.3).
String normalizeBrandText(String input) {
  var s = input.toLowerCase().trim();
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  for (var i = 0; i < from.length; i++) {
    s = s.replaceAll(from[i], to[i]);
  }
  return s.replaceAll(RegExp(r'[\s\-_.]+'), ' ').trim();
}

bool _matches(String normalized, BrandMatcher m) {
  switch (m.kind) {
    case MatchKind.exact:
      return normalized == m.alias;
    case MatchKind.word:
      // Palabra completa: evita 'paypal' dentro de 'mipaypalito', 'arq' en
      // 'marqueta'. RegExp.escape protege aliases con caracteres especiales.
      final re = RegExp('(^|\\s)${RegExp.escape(m.alias)}(\\s|\$)');
      return re.hasMatch(normalized);
    case MatchKind.contains:
      return normalized.contains(m.alias);
  }
}

/// Detecta la marca de un nombre de cuenta. Itera [kBankBrands] en orden de
/// especificidad y devuelve el PRIMER match, o null si es desconocido (o vacío).
BankBrand? detectBrand(String name) {
  final n = normalizeBrandText(name);
  if (n.isEmpty) return null;
  for (final brand in kBankBrands) {
    for (final m in brand.matchers) {
      if (_matches(n, m)) return brand;
    }
  }
  return null;
}
