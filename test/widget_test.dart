import 'package:flutter_lab/rut.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valida RUT con dígito verificador', () {
    expect(isValidRut('12.345.678-5'), isTrue);
    expect(isValidRut('11.111.111-1'), isTrue);
    expect(isValidRut('12.345.678-9'), isFalse);
    expect(isValidRut('1'), isFalse);
  });

  test('da formato al RUT mientras se escribe', () {
    final out = RutFormatter().formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '123456785'));
    expect(out.text, '12.345.678-5');
  });
}
