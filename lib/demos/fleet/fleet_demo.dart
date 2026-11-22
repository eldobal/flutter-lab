import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../main.dart';
import 'fleet_model.dart';

/// Mapa de flota en tiempo real (simulado): buses que se mueven por Santiago,
/// con detalle al tocar cada uno y modo "seguir".
class FleetDemo extends StatefulWidget {
  const FleetDemo({super.key});

  @override
  State<FleetDemo> createState() => _FleetDemoState();
}

class _FleetDemoState extends State<FleetDemo> with SingleTickerProviderStateMixin {
  final _rand = Random(42);
  late final List<Vehicle> _fleet = buildFleet(_rand);
  final _map = MapController();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Vehicle? _selected;
  bool _follow = false;
  bool _mapReady = false;

  /// Avanza con cada paso de la simulación. Solo lo escuchan los buses y los textos en vivo:
  /// las tiles, rutas y paradas no se reconstruyen mientras los buses se mueven.
  final _tick = ValueNotifier<int>(0);

  /// La simulación corre a ~30 pasos por segundo: a x4 no se nota la diferencia con 60.
  static const _step = Duration(microseconds: 33333);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (elapsed - _last < _step) return;
      // Simulación acelerada x4 para que el movimiento se note
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1) * 4;
      _last = elapsed;
      for (final v in _fleet) {
        v.step(dt, _rand);
      }
      if (_follow && _selected != null && _mapReady) {
        _map.move(_selected!.position.point, _map.camera.zoom);
      }
      _tick.value++;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    _map.dispose();
    super.dispose();
  }

  void _select(Vehicle v) {
    setState(() {
      _selected = v;
      _follow = true;
    });
    _map.move(v.position.point, max(_map.camera.zoom, 14));
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: const LatLng(-33.440, -70.620),
            initialZoom: 12.4,
            minZoom: 10,
            maxZoom: 17,
            backgroundColor: const Color(0xFF0E1116),
            onMapReady: () => _mapReady = true,
            onTap: (_, _) => setState(() => _selected = null),
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            // Tiles de OSM invertidos para un mapa oscuro, sin API key. Un solo filtro
            // para toda la capa (darkModeTileBuilder aplica uno por tile, más caro en web).
            ColorFiltered(
              colorFilter: _darkTiles,
              child: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'cl.baldovinos.flutter_lab',
              ),
            ),
            PolylineLayer(
              polylines: [
                for (final r in fleetRoutes)
                  Polyline(
                    points: r.points,
                    strokeWidth: _selected?.route == r ? 6 : 3.5,
                    color: Color(r.colorValue).withValues(alpha: _selected == null || _selected!.route == r ? 0.85 : 0.25),
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final r in fleetRoutes)
                  for (final stop in r.stops)
                    Marker(
                      point: stop.point,
                      width: 10,
                      height: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(r.colorValue), width: 2),
                        ),
                      ),
                    ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: _tick,
              builder: (context, _, _) => MarkerLayer(
                markers: [
                  for (final v in _fleet)
                    Marker(
                      point: v.position.point,
                      width: 44,
                      height: 44,
                      child: _BusMarker(vehicle: v, selected: v == _selected, onTap: () => _select(v)),
                    ),
                ],
              ),
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
        // Resumen de la flota
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _Glass(
            child: Row(
              children: [
                const _LiveDot(),
                const SizedBox(width: 8),
                Text(s.fleetLive, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                ValueListenableBuilder(
                  valueListenable: _tick,
                  builder: (context, _, _) => Text(
                    s.fleetSummary(_fleet.length, _fleet.where((v) => !v.stopped).length),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Detalle del bus seleccionado
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, a) => SlideTransition(
              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: _selected == null
                ? _Glass(
                    key: const ValueKey('hint'),
                    child: Text(s.fleetHint, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13)),
                  )
                : ValueListenableBuilder(
                    key: ValueKey(_selected!.code),
                    valueListenable: _tick,
                    builder: (context, _, _) => _VehicleCard(
                      vehicle: _selected!,
                      follow: _follow,
                      onFollow: () => setState(() {
                        _follow = !_follow;
                        if (_follow) _map.move(_selected!.position.point, _map.camera.zoom);
                      }),
                      onClose: () => setState(() => _selected = null),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Mismo filtro que `darkModeTileBuilder` de flutter_map: invierte y rota el tono 180°.
const _darkTiles = ColorFilter.matrix(<double>[
  0.574, -1.43, -0.144, 0, 255, //
  -0.426, -0.43, -0.144, 0, 255, //
  -0.426, -1.43, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

class _BusMarker extends StatelessWidget {
  const _BusMarker({required this.vehicle, required this.selected, required this.onTap});
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(vehicle.route.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.25 : 1,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.25)),
              ),
            // Flecha de rumbo
            Transform.rotate(
              angle: vehicle.position.heading * pi / 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.arrow_drop_up_rounded, color: color, size: 22),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: ink, width: 2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)],
              ),
              child: Icon(vehicle.stopped ? Icons.pause_rounded : Icons.directions_bus_rounded, size: 15, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.follow, required this.onFollow, required this.onClose});
  final Vehicle vehicle;
  final bool follow;
  final VoidCallback onFollow;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final v = vehicle;
    final color = Color(v.route.colorValue);
    final occupancy = v.passengers / v.capacity;
    final eta = v.etaSeconds;
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(v.route.name, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(v.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text(v.plate, style: const TextStyle(color: muted, fontSize: 12)),
              const Spacer(),
              InkWell(onTap: onClose, child: const Icon(Icons.close_rounded, color: muted, size: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: s.fleetSpeed, value: '${v.kmh.round()} km/h'),
              _Metric(label: s.fleetNextStop, value: v.nextStop.name),
              _Metric(label: 'ETA', value: eta < 60 ? '${eta}s' : '${(eta / 60).ceil()} min'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${s.fleetOccupancy} ${v.passengers}/${v.capacity}', style: const TextStyle(color: muted, fontSize: 12)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: occupancy),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: surfaceHigh,
                      color: value > 0.85 ? Colors.redAccent : color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('${s.fleetDriver}: ${v.driver}', style: const TextStyle(color: muted, fontSize: 12))),
              TextButton.icon(
                onPressed: onFollow,
                icon: Icon(follow ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded, size: 18),
                label: Text(follow ? s.fleetFollowing : s.fleetFollow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3140)),
      ),
      child: child,
    );
  }
}

/// Punto verde que "late" para indicar datos en vivo.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: accent, shape: BoxShape.circle)),
    );
  }
}
