import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Flota simulada para la demo: buses que recorren avenidas reales de Santiago, ida y vuelta.
/// Todos los datos (patentes, conductores, pasajeros) son ficticios.

class Stop {
  const Stop(this.name, this.point);
  final String name;
  final LatLng point;
}

class FleetRoute {
  FleetRoute(this.id, this.name, this.colorValue, this.stops) {
    var total = 0.0;
    _cumulative.add(0);
    for (var i = 1; i < stops.length; i++) {
      total += _distance(stops[i - 1].point, stops[i].point);
      _cumulative.add(total);
    }
    length = total;
  }

  final String id;
  final String name;
  final int colorValue;
  final List<Stop> stops;
  final List<double> _cumulative = [];
  late final double length;

  List<LatLng> get points => [for (final s in stops) s.point];

  /// Posición y rumbo a una distancia recorrida desde la primera parada.
  ({LatLng point, double heading, int segment}) at(double meters) {
    final d = meters.clamp(0.0, length);
    var i = 1;
    while (i < _cumulative.length - 1 && _cumulative[i] < d) {
      i++;
    }
    final a = stops[i - 1].point, b = stops[i].point;
    final segLength = _cumulative[i] - _cumulative[i - 1];
    final t = segLength == 0 ? 0.0 : (d - _cumulative[i - 1]) / segLength;
    final point = LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);
    return (point: point, heading: _bearing(a, b), segment: i);
  }

  /// Distancia (en metros) de la parada `index` desde el inicio.
  double stopDistance(int index) => _cumulative[index];
}

const _haversine = Distance();
double _distance(LatLng a, LatLng b) => _haversine.as(LengthUnit.Meter, a, b);
double _bearing(LatLng a, LatLng b) => _haversine.bearing(a, b);

final fleetRoutes = [
  FleetRoute('alameda', 'Alameda', 0xFF7CF29C, const [
    Stop('Estación Central', LatLng(-33.4517, -70.6787)),
    Stop('Los Héroes', LatLng(-33.4462, -70.6603)),
    Stop('La Moneda', LatLng(-33.4436, -70.6541)),
    Stop('Santa Lucía', LatLng(-33.4425, -70.6440)),
    Stop('Baquedano', LatLng(-33.4370, -70.6345)),
    Stop('Pedro de Valdivia', LatLng(-33.4253, -70.6143)),
    Stop('Tobalaba', LatLng(-33.4180, -70.6015)),
  ]),
  FleetRoute('vicuna', 'Vicuña Mackenna', 0xFF4C6FFF, const [
    Stop('Baquedano', LatLng(-33.4370, -70.6345)),
    Stop('Santa Isabel', LatLng(-33.4480, -70.6318)),
    Stop('Irarrázaval', LatLng(-33.4545, -70.6283)),
    Stop('Ñuble', LatLng(-33.4672, -70.6232)),
    Stop('Rodrigo de Araya', LatLng(-33.4775, -70.6180)),
    Stop('Pedrero', LatLng(-33.5030, -70.6110)),
  ]),
  FleetRoute('apoquindo', 'Apoquindo', 0xFFF59E0B, const [
    Stop('Tobalaba', LatLng(-33.4180, -70.6015)),
    Stop('El Golf', LatLng(-33.4165, -70.5965)),
    Stop('Escuela Militar', LatLng(-33.4136, -70.5832)),
    Stop('Manquehue', LatLng(-33.4096, -70.5675)),
    Stop('Los Dominicos', LatLng(-33.4080, -70.5442)),
  ]),
];

class Vehicle {
  Vehicle({
    required this.code,
    required this.plate,
    required this.driver,
    required this.route,
    required this.distance,
    required this.speed,
    required this.capacity,
    required this.passengers,
    this.forward = true,
  });

  final String code;
  final String plate;
  final String driver;
  final FleetRoute route;
  double distance;
  double speed; // m/s
  final int capacity;
  int passengers;
  bool forward;
  double _dwell = 0; // segundos detenido en una parada

  bool get stopped => _dwell > 0;
  double get kmh => stopped ? 0 : speed * 3.6;

  ({LatLng point, double heading, int segment}) get position {
    final p = route.at(distance);
    return (point: p.point, heading: forward ? p.heading : (p.heading + 180) % 360, segment: p.segment);
  }

  /// Próxima parada en el sentido del viaje.
  Stop get nextStop {
    final seg = route.at(distance).segment;
    return forward ? route.stops[seg] : route.stops[seg - 1];
  }

  /// Segundos estimados hasta la próxima parada.
  int get etaSeconds {
    final seg = route.at(distance).segment;
    final target = forward ? route.stopDistance(seg) : route.stopDistance(seg - 1);
    return ((target - distance).abs() / max(speed, 1)).round() + _dwell.round();
  }

  void step(double dt, Random rand) {
    if (_dwell > 0) {
      _dwell = max(0, _dwell - dt);
      return;
    }
    final before = route.at(distance).segment;
    distance += (forward ? 1 : -1) * speed * dt;
    // Pequeñas variaciones de velocidad, como en el tráfico real
    speed = (speed + (rand.nextDouble() - 0.5) * dt * 3).clamp(7.0, 16.0);
    if (distance >= route.length || distance <= 0) {
      distance = distance.clamp(0.0, route.length);
      forward = !forward;
      _dwell = 6;
      return;
    }
    if (route.at(distance).segment != before) {
      _dwell = 2 + rand.nextDouble() * 3;
      passengers = (passengers + rand.nextInt(9) - 4).clamp(0, capacity);
    }
  }
}

List<Vehicle> buildFleet(Random rand) {
  const drivers = ['M. Rojas', 'C. Pérez', 'J. Soto', 'A. Muñoz', 'P. Díaz', 'F. Silva', 'R. Vega', 'L. Torres'];
  final vehicles = <Vehicle>[];
  var n = 101;
  for (final route in fleetRoutes) {
    final count = route.length > 6000 ? 3 : 2;
    for (var i = 0; i < count; i++) {
      vehicles.add(Vehicle(
        code: 'BUS-${n++}',
        plate: 'DEMO-${10 + rand.nextInt(89)}',
        driver: drivers[vehicles.length % drivers.length],
        route: route,
        distance: route.length * (i + rand.nextDouble() * 0.6) / count,
        speed: 9 + rand.nextDouble() * 5,
        capacity: 40,
        passengers: 8 + rand.nextInt(28),
        forward: rand.nextBool(),
      ));
    }
  }
  return vehicles;
}
