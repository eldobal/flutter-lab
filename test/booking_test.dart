import 'dart:math';

import 'package:flutter_lab/demos/booking/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los asientos ocupados son estables para el mismo viaje', () {
    final date = DateTime(2026, 12, 1);
    final a = occupiedSeats('stgo-valpo', date, '07:00');
    expect(a, occupiedSeats('stgo-valpo', date, '07:00'));
    expect(a.length, inInclusiveRange(12, 25));
    expect(a.every((seat) => RegExp(r'^(10|[1-9])[A-D]$').hasMatch(seat)), isTrue);
  });

  test('calcula la hora de llegada, incluso pasada la medianoche', () {
    expect(arrivalTime('07:00', 105), '08:45');
    expect(arrivalTime('21:40', 180), '00:40');
  });

  test('el código de reserva tiene 6 caracteres sin ambiguos', () {
    final code = bookingCode(Random(1));
    expect(code, hasLength(6));
    expect(code.contains(RegExp('[01IO]')), isFalse);
  });

  test('una reserva se guarda y se recupera en JSON', () {
    final booking = Booking(code: 'ABC234', routeId: 'anto-calama', date: DateTime(2026, 12, 3), time: '13:00', seat: '4C', name: 'Ana', rut: '12.345.678-5');
    final copy = Booking.fromJson(booking.toJson());
    expect(copy.qrPayload, booking.qrPayload);
    expect(copy.route.to, 'Calama');
  });
}
