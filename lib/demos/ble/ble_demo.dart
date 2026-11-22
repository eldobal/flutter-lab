import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../strings.dart';
import '../common.dart';
import 'ble_model.dart';

/// Inspirado en la POC Bluetooth BLE (GATT): escaneo con radar, conexión,
/// servicios y características, y una cerradura que se bloquea y desbloquea.
/// El navegador no accede al Bluetooth aquí: los periféricos son simulados.
class BleDemo extends StatefulWidget {
  const BleDemo({super.key});

  @override
  State<BleDemo> createState() => _BleDemoState();
}

const _blue = Color(0xFF0EA5E9);

class _BleDemoState extends State<BleDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _radar = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  final _rand = Random();
  final _devices = nearbyDevices();
  final _found = <FakeDevice>[];
  final _lock = FakeLock();
  final _log = <String>[];
  Timer? _timer;
  FakeDevice? _connected;
  bool _connecting = false;
  bool _busy = false;
  int? _battery;

  @override
  void initState() {
    super.initState();
    // Cada tick aparece un dispositivo nuevo y el RSSI de los encontrados varía
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      setState(() {
        if (_found.length < _devices.length) _found.add(_devices[_found.length]);
        for (final d in _found) {
          d.jitter(_rand);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _radar.dispose();
    super.dispose();
  }

  void _addLog(String line) {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    _log.insert(0, '${two(t.minute)}:${two(t.second)}  $line');
  }

  Future<void> _connect(FakeDevice d, S s) async {
    if (!d.isLock) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(s.t('En este demo solo la cerradura acepta conexión.', 'In this demo only the lock accepts connections.')),
            behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _connecting = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _connected = d;
      _log.clear();
      _addLog('CONNECT ${d.id}');
      _addLog('DISCOVER ${s.t('3 características', '3 characteristics')}');
      _addLog('SUBSCRIBE state');
      _addLog('READ state → ${hex(_lock.readState())}');
    });
  }

  Future<void> _toggleLock() async {
    final command = [_lock.locked ? 0x00 : 0x01];
    setState(() {
      _busy = true;
      _addLog('WRITE command ← ${hex(command)}');
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final notification = _lock.write(command);
    setState(() {
      _busy = false;
      _addLog('NOTIFY state → ${hex(notification!)}');
    });
  }

  void _readBattery() => setState(() {
        _battery = _lock.battery;
        _addLog('READ battery → ${hex([_lock.battery])} ($_battery%)');
      });

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _connected == null ? _scanView(s) : _deviceView(s, _connected!),
    );
  }

  Widget _scanView(S s) {
    final sorted = [..._found]..sort((a, b) => b.rssi.compareTo(a.rssi));
    return ListView(
      key: const ValueKey('scan'),
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: _radar,
              builder: (context, _) => CustomPaint(painter: _RadarPainter(_radar.value, _found)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LabLabel(s.t('Dispositivos cercanos · ${_found.length}', 'Nearby devices · ${_found.length}')),
        for (final d in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _connecting ? null : () => _connect(d, s),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(d.isLock ? Icons.lock_rounded : Icons.bluetooth_rounded, color: d.isLock ? _blue : muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            Text(d.id, style: const TextStyle(color: muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (_connecting && d.isLock)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                      else ...[
                        _SignalBars(rssi: d.rssi),
                        const SizedBox(width: 6),
                        SizedBox(width: 62, child: Text('${d.rssi} dBm', textAlign: TextAlign.end, style: const TextStyle(color: muted, fontSize: 12))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(s.t('Periféricos simulados: el navegador no accede a tu Bluetooth.', "Simulated peripherals: the browser doesn't access your Bluetooth."),
            textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }

  Widget _deviceView(S s, FakeDevice d) {
    final locked = _lock.locked;
    final color = locked ? const Color(0xFFF87171) : accent;
    return ListView(
      key: const ValueKey('device'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.bluetooth_connected_rounded, color: _blue),
            const SizedBox(width: 8),
            Expanded(child: Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
            TextButton(onPressed: () => setState(() => _connected = null), child: Text(s.t('Desconectar', 'Disconnect'))),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _toggleLock,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 3),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16)],
              ),
              child: _busy
                  ? const Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator.adaptive()))
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(locked ? Icons.lock_rounded : Icons.lock_open_rounded, key: ValueKey(locked), color: color, size: 64),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(locked ? s.t('Bloqueada · toca para abrir', 'Locked · tap to open') : s.t('Desbloqueada · toca para cerrar', 'Unlocked · tap to lock'),
            textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        LabLabel(s.t('Servicio GATT', 'GATT service')),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              _CharRow(name: 'state', uuid: stateCharUuid, props: 'READ · NOTIFY', value: hex(_lock.readState())),
              const Divider(height: 1, color: surfaceHigh),
              _CharRow(name: 'command', uuid: commandCharUuid, props: 'WRITE', value: '—'),
              const Divider(height: 1, color: surfaceHigh),
              _CharRow(
                name: 'battery',
                uuid: batteryCharUuid,
                props: 'READ',
                value: _battery == null ? '—' : '$_battery%',
                action: IconButton(onPressed: _readBattery, icon: const Icon(Icons.download_rounded, color: _blue, size: 20), tooltip: 'READ'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LabLabel('Log'),
        Panel(
          color: const Color(0xFF0A0D12),
          child: SizedBox(
            height: 130,
            child: ListView(
              children: [
                for (final l in _log)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l, style: TextStyle(color: l.contains('NOTIFY') ? accent : const Color(0xFFCBD5E1), fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CharRow extends StatelessWidget {
  const _CharRow({required this.name, required this.uuid, required this.props, required this.value, this.action});
  final String name;
  final String uuid;
  final String props;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${uuid.substring(0, 8)}… · $props', style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ?action,
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.rssi});
  final int rssi;

  @override
  Widget build(BuildContext context) {
    final level = rssi > -60 ? 4 : rssi > -70 ? 3 : rssi > -80 ? 2 : 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= 4; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 4,
            height: 4.0 + i * 3,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(color: i <= level ? _blue : surfaceHigh, borderRadius: BorderRadius.circular(1)),
          ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t, this.devices);
  final double t;
  final List<FakeDevice> devices;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = Paint()
      ..color = _blue.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, r * i / 3, ring);
    }
    // Barrido giratorio
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi / 2,
        colors: [_blue.withValues(alpha: 0), _blue.withValues(alpha: 0.45)],
        transform: GradientRotation(t * 2 * pi - pi / 2),
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, sweep);
    // Dispositivos según su distancia (RSSI)
    for (final d in devices) {
      final p = c + Offset(cos(d.angle), sin(d.angle)) * r * d.distance * 0.92;
      canvas.drawCircle(p, d.isLock ? 7 : 5, Paint()..color = d.isLock ? accent : Colors.white70);
      canvas.drawCircle(p, d.isLock ? 13 : 9, Paint()..color = (d.isLock ? accent : Colors.white).withValues(alpha: 0.15));
    }
    canvas.drawCircle(c, 6, Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => true;
}
