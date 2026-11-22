import 'package:flutter_lab/demos/ble/ble_model.dart';
import 'package:flutter_lab/demos/embark/embark_model.dart';
import 'package:flutter_lab/demos/totem/receipt.dart';
import 'package:flutter_lab/plate.dart';
import 'package:flutter_lab/rut.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('patentes', () {
    test('valida formato antiguo y nuevo', () {
      expect(isValidPlate('BCDF12'), isTrue);
      expect(isValidPlate('ab-1234'), isTrue);
      expect(isValidPlate('BCDE12'), isFalse); // vocal en formato nuevo
      expect(isValidPlate('ABC123'), isFalse);
      expect(formatPlate('bcdf12'), 'BC·DF·12');
    });

    test('corrige errores típicos del OCR por posición', () {
      expect(fixOcrPlate('LPR556'), 'LPRS56');
      expect(fixOcrPlate('KR452I'), 'KR4521');
      expect(fixOcrPlate('HJPT9O'), 'HJPT90');
      expect(fixOcrPlate('6HJK34'), 'GHJK34');
      expect(fixOcrPlate('XYZ'), isNull);
    });
  });

  test('rutFromNumber genera RUT válidos', () {
    expect(rutFromNumber(12345678), '12.345.678-5');
    for (var n = 5000000; n < 5000300; n++) {
      expect(isValidRut(rutFromNumber(n)), isTrue);
    }
  });

  test('embarque: duplicados, inválidos y sincronización sin conexión', () {
    final session = BoardingSession(service: 'X', plate: 'BCDF12', capacity: 2);
    expect(session.add('12.345.678-9', 'A'), AddResult.invalid);
    expect(session.add('12345678-5', 'A'), AddResult.added);
    expect(session.add('12.345.678-5', 'A'), AddResult.duplicate);
    session.online = false;
    expect(session.add('11.111.111-1', 'B'), AddResult.added);
    expect(session.pending, 1);
    expect(session.sync(), 0);
    expect(session.add(rutFromNumber(7654321), 'C'), AddResult.full);
    session.online = true;
    expect(session.sync(), 1);
    expect(session.pending, 0);
  });

  test('comprobante de 58 mm: ninguna línea pasa de 32 columnas', () {
    final lines = buildReceipt(
      rut: '12.345.678-5', route: 'Campamento', date: '21/11/2026', time: '19:00', seat: '7C', bus: 'BUS-120', code: 'SGT-4821',
      labels: const {'title': 'COMPROBANTE', 'rut': 'RUT', 'route': 'Ruta', 'date': 'Fecha', 'time': 'Salida', 'bus': 'Bus', 'seat': 'ASIENTO', 'footer': 'Buen viaje'},
    );
    expect(lines.every((l) => l.length <= receiptWidth), isTrue);
    expect(lines, contains(predicate<String>((l) => l.startsWith('RUT') && l.endsWith('12.345.678-5'))));
  });

  test('cerradura BLE: comandos válidos y notificación de estado', () {
    final lock = FakeLock();
    expect(lock.readState(), [0x01]);
    expect(lock.write([0x00]), [0x00]);
    expect(lock.locked, isFalse);
    expect(lock.write([0x07]), isNull);
    expect(lock.write([0x01, 0x00]), isNull);
    expect(hex([0x01, 0xAB]), '0x01 0xAB');
  });
}
