import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Datos ficticios de la demo de reservas: rutas, horarios, asientos y reservas guardadas.

class BusRoute {
  const BusRoute(this.id, this.from, this.to, this.minutes, this.price);
  final String id;
  final String from;
  final String to;
  final int minutes;
  final int price;
}

const routes = [
  BusRoute('stgo-valpo', 'Santiago', 'Valparaíso', 105, 5900),
  BusRoute('stgo-rancagua', 'Santiago', 'Rancagua', 75, 3900),
  BusRoute('anto-calama', 'Antofagasta', 'Calama', 180, 8900),
];

const departures = ['07:00', '09:30', '13:00', '18:15', '21:40'];

const seatRows = 10;
const seatCols = ['A', 'B', 'C', 'D'];

/// Asientos ocupados, siempre los mismos para una misma ruta, fecha y hora.
Set<String> occupiedSeats(String routeId, DateTime date, String time) {
  final seed = '$routeId-${date.year}${date.month}${date.day}-$time'.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  final rand = Random(seed);
  final occupied = <String>{};
  final target = 12 + rand.nextInt(14);
  while (occupied.length < target) {
    occupied.add('${rand.nextInt(seatRows) + 1}${seatCols[rand.nextInt(seatCols.length)]}');
  }
  return occupied;
}

/// Hora de llegada a partir de la salida y la duración.
String arrivalTime(String departure, int minutes) {
  final parts = departure.split(':').map(int.parse).toList();
  final total = parts[0] * 60 + parts[1] + minutes;
  return '${(total ~/ 60 % 24).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}

/// Código de reserva corto, legible y sin caracteres ambiguos.
String bookingCode(Random rand) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return List.generate(6, (_) => alphabet[rand.nextInt(alphabet.length)]).join();
}

class Booking {
  const Booking({
    required this.code,
    required this.routeId,
    required this.date,
    required this.time,
    required this.seat,
    required this.name,
    required this.rut,
  });

  final String code;
  final String routeId;
  final DateTime date;
  final String time;
  final String seat;
  final String name;
  final String rut;

  BusRoute get route => routes.firstWhere((r) => r.id == routeId);

  /// Contenido del QR del pase de abordaje.
  String get qrPayload => 'FLUTTERLAB|$code|$routeId|${date.toIso8601String().substring(0, 10)}|$time|$seat';

  Map<String, Object> toJson() => {
        'code': code,
        'routeId': routeId,
        'date': date.toIso8601String(),
        'time': time,
        'seat': seat,
        'name': name,
        'rut': rut,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        code: json['code'] as String,
        routeId: json['routeId'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        seat: json['seat'] as String,
        name: json['name'] as String,
        rut: json['rut'] as String,
      );
}

/// Reservas del usuario, guardadas en el navegador (localStorage vía shared_preferences).
class BookingStore extends ChangeNotifier {
  BookingStore._();
  static final instance = BookingStore._();
  static const _key = 'flutterlab-bookings';

  final List<Booking> _bookings = [];
  bool _loaded = false;
  List<Booking> get bookings => List.unmodifiable(_bookings);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _bookings.addAll((jsonDecode(raw) as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // Sin almacenamiento (modo privado, etc.): las reservas viven solo en memoria
    }
    notifyListeners();
  }

  Future<void> add(Booking booking) async {
    _bookings.insert(0, booking);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String code) async {
    _bookings.removeWhere((b) => b.code == code);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_bookings.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }
}
