import 'package:flutter/services.dart';

/// Valida un RUT chileno con su dígito verificador (módulo 11).
bool isValidRut(String input) {
  final clean = input.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (clean.length < 2) return false;
  final body = clean.substring(0, clean.length - 1);
  final dv = clean[clean.length - 1];
  if (!RegExp(r'^\d+$').hasMatch(body)) return false;
  var sum = 0, factor = 2;
  for (var i = body.length - 1; i >= 0; i--) {
    sum += int.parse(body[i]) * factor;
    factor = factor == 7 ? 2 : factor + 1;
  }
  final expected = switch (11 - sum % 11) { 11 => '0', 10 => 'K', final n => '$n' };
  return dv == expected;
}

/// Da formato 12.345.678-5 mientras se escribe.
class RutFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var clean = newValue.text.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (clean.length > 9) clean = clean.substring(0, 9);
    if (clean.length < 2) return TextEditingValue(text: clean, selection: TextSelection.collapsed(offset: clean.length));
    final body = clean.substring(0, clean.length - 1);
    final dv = clean[clean.length - 1];
    final buffer = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) buffer.write('.');
      buffer.write(body[i]);
    }
    final text = '$buffer-$dv';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Formatea un RUT ya escrito: 123456785 → 12.345.678-5.
String formatRut(String input) =>
    RutFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: input)).text;

/// Arma un RUT válido (con su dígito verificador) a partir del número: 12345678 → 12.345.678-5.
String rutFromNumber(int number) {
  final body = '$number';
  var sum = 0, factor = 2;
  for (var i = body.length - 1; i >= 0; i--) {
    sum += int.parse(body[i]) * factor;
    factor = factor == 7 ? 2 : factor + 1;
  }
  final dv = switch (11 - sum % 11) { 11 => '0', 10 => 'K', final n => '$n' };
  return formatRut('$body$dv');
}
