/// Patentes chilenas: formato antiguo (AB·12·34) y nuevo (BC·DF·12, solo consonantes).
String normalizePlate(String input) => input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

bool isValidPlate(String input) {
  final p = normalizePlate(input);
  return RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(p) || RegExp(r'^[BCDFGHJKLPRSTVWXYZ]{4}\d{2}$').hasMatch(p);
}

/// Da formato de placa: BCDF12 → BC·DF·12.
String formatPlate(String input) {
  final p = normalizePlate(input);
  if (p.length != 6) return p;
  return '${p.substring(0, 2)}·${p.substring(2, 4)}·${p.substring(4)}';
}

const _toLetter = {'0': 'D', '8': 'B', '5': 'S', '2': 'Z', '6': 'G', '1': 'L', '4': 'A'};
const _toDigit = {'O': '0', 'D': '0', 'Q': '0', 'I': '1', 'L': '1', 'B': '8', 'S': '5', 'Z': '2', 'G': '6', 'A': '4', 'T': '7'};

/// Corrige confusiones típicas del OCR (O/0, S/5, B/8...) según la posición de cada carácter.
/// Prueba primero el formato nuevo y luego el antiguo. Devuelve null si no calza ninguno.
String? fixOcrPlate(String raw) {
  final p = normalizePlate(raw);
  if (p.length != 6) return null;
  String fix(int letters) => [
        for (var i = 0; i < 6; i++)
          i < letters ? (_toLetter[p[i]] ?? p[i]) : (_toDigit[p[i]] ?? p[i]),
      ].join();
  for (final candidate in [fix(4), fix(2)]) {
    if (isValidPlate(candidate)) return candidate;
  }
  return null;
}
