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
    asset: 'assets/brands/daviplata.svg',
    matchers: [BrandMatcher('daviplata')], // word
  ),
  BankBrand(
    id: 'davivienda',
    displayName: 'Davivienda',
    primary: Color(0xFFED1C24),
    accent: Color(0xFFC4161C),
    asset: 'assets/brands/davivienda.svg',
    matchers: [BrandMatcher('davivienda', MatchKind.contains)],
  ),
  BankBrand(
    id: 'bancolombia',
    displayName: 'Bancolombia',
    primary: Color(0xFFFFD200),
    secondary: Color(0xFFFFC107),
    accent: Color(0xFF8A6D00), // amarillo no contrasta -> accent oscuro
    asset: 'assets/brands/bancolombia.svg',
    matchers: [BrandMatcher('bancolombia', MatchKind.contains)],
  ),
  BankBrand(
    id: 'nequi',
    displayName: 'Nequi',
    primary: Color(0xFFDA0081),
    secondary: Color(0xFF20104A),
    accent: Color(0xFFB80070),
    asset: 'assets/brands/nequi.svg',
    matchers: [BrandMatcher('nequi')], // word
  ),
  BankBrand(
    id: 'nubank',
    displayName: 'Nubank',
    primary: Color(0xFF820AD1),
    accent: Color(0xFF820AD1),
    asset: 'assets/brands/nubank.svg',
    matchers: [
      BrandMatcher('nubank', MatchKind.contains),
      BrandMatcher('nu', MatchKind.exact), // 'nu' SOLO exacto (nunca en 'menu')
    ],
  ),
  // CORRECCIÓN recon (Fase 2): Pibank es AMARILLO (#FFDC00), no verde. accent
  // oscuro (azul navy) porque el amarillo no contrasta sobre superficie clara.
  BankBrand(
    id: 'pibank',
    displayName: 'Pibank',
    primary: Color(0xFFFFDC00),
    secondary: Color(0xFF0F265C),
    accent: Color(0xFF0F265C),
    asset: 'assets/brands/pibank.svg',
    matchers: [BrandMatcher('pibank', MatchKind.contains)],
  ),
  // CORRECCIÓN recon (Fase 2): Trii es VERDE (#02FB7E), no navy. accent navy
  // oscuro para texto legible (el verde claro no contrasta sobre fondo claro).
  BankBrand(
    id: 'trii',
    displayName: 'Trii',
    primary: Color(0xFF02FB7E),
    secondary: Color(0xFF03CA62),
    accent: Color(0xFF0A4A2C),
    asset: 'assets/brands/trii.svg',
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
    asset: 'assets/brands/paypal.svg',
    matchers: [BrandMatcher('paypal')], // word
  ),
  BankBrand(
    id: 'mercadopago',
    displayName: 'Mercado Pago',
    primary: Color(0xFF009EE3),
    accent: Color(0xFF007EB5),
    asset: 'assets/brands/mercadopago.svg',
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
    asset: 'assets/brands/dolarapp.svg',
    matchers: [BrandMatcher('dolarapp', MatchKind.contains)],
  ),
  // CORRECCIÓN recon (Fase 2): ARQ ("A la Mano") es NEGRO, no rojo. secondary
  // marrón oscuro (#3E0F00) de su identidad; accent gris oscuro contrastable.
  BankBrand(
    id: 'arq',
    displayName: 'A la Mano (ARQ)',
    primary: Color(0xFF000000),
    secondary: Color(0xFF3E0F00),
    accent: Color(0xFF1A1A1A),
    asset: 'assets/brands/arq.svg',
    matchers: [
      BrandMatcher('arq'), // word (no matchea 'marqueta')
      BrandMatcher('a la mano', MatchKind.contains),
    ],
  ),
  // CORRECCIÓN recon (Fase 2): Global66 es AZUL (#2745C7), no verde.
  BankBrand(
    id: 'global66',
    displayName: 'Global66',
    primary: Color(0xFF2745C7),
    secondary: Color(0xFF4D66D0),
    accent: Color(0xFF1E369E),
    asset: 'assets/brands/global66.png',
    matchers: [BrandMatcher('global66', MatchKind.contains)],
  ),
  BankBrand(
    id: 'payu',
    displayName: 'PayU',
    primary: Color(0xFFA6C307),
    accent: Color(0xFF7E9400),
    asset: 'assets/brands/payu.png',
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
