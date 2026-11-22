import 'dart:math';

import 'package:flutter_lab/demos/fleet/fleet_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las rutas tienen largo realista', () {
    for (final r in fleetRoutes) {
      expect(r.length, greaterThan(2000));
      expect(r.length, lessThan(20000));
    }
  });

  test('at() interpola entre la primera y la última parada', () {
    final r = fleetRoutes.first;
    expect(r.at(0).point, r.stops.first.point);
    expect(r.at(r.length).point.latitude, closeTo(r.stops.last.point.latitude, 1e-9));
    expect(r.at(-50).point, r.stops.first.point);
  });

  test('los buses se mueven, se detienen y dan la vuelta sin salirse de la ruta', () {
    final rand = Random(1);
    final fleet = buildFleet(rand);
    expect(fleet, isNotEmpty);
    final start = [for (final v in fleet) v.distance];
    final turned = <String>{};
    for (var i = 0; i < 20000; i++) {
      for (final v in fleet) {
        final before = v.forward;
        v.step(0.1, rand);
        if (v.forward != before) turned.add(v.code);
        expect(v.distance, inInclusiveRange(0, v.route.length));
        expect(v.passengers, inInclusiveRange(0, v.capacity));
        expect(v.etaSeconds, greaterThanOrEqualTo(0));
        expect(v.route.stops, contains(v.nextStop));
      }
    }
    expect([for (final v in fleet) v.distance], isNot(start));
    expect(turned, isNotEmpty);
  });
}
