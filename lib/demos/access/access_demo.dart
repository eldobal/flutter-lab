import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../plate.dart';
import '../../rut.dart';
import '../../strings.dart';
import '../common.dart';

/// Inspirado en MiAcceso: el conductor se registra con su RUT, la empresa aprueba
/// su acceso (aviso tipo push), elige el vehículo y registra la duración del viaje.
class AccessDemo extends StatefulWidget {
  const AccessDemo({super.key});

  @override
  State<AccessDemo> createState() => _AccessDemoState();
}

enum _Step { register, pending, vehicle, trip }

const _fleetPlates = ['BCDF12', 'GHJK34', 'LPRS56', 'TVWX78', 'KR4521', 'ZD7788', 'HJPT90', 'FW1203'];

class _Trip {
  _Trip(this.plate, this.duration);
  final String plate;
  final Duration duration;
}

class _AccessDemoState extends State<AccessDemo> {
  _Step _step = _Step.register;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _rut = TextEditingController();
  final _search = TextEditingController();
  String? _plate;
  DateTime? _start;
  Timer? _timer;
  bool _banner = false;
  final List<_Trip> _trips = [];

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _rut.dispose();
    _search.dispose();
    super.dispose();
  }

  void _register() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.pending);
    // La "empresa" aprueba el acceso después de unos segundos
    _timer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() {
        _banner = true;
        _step = _Step.vehicle;
      });
      Timer(const Duration(seconds: 3), () => mounted ? setState(() => _banner = false) : null);
    });
  }

  void _startTrip(String plate) {
    setState(() {
      _plate = plate;
      _start = DateTime.now();
      _step = _Step.trip;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  void _endTrip() {
    _timer?.cancel();
    setState(() {
      _trips.insert(0, _Trip(_plate!, DateTime.now().difference(_start!)));
      _step = _Step.vehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a), child: child),
          ),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              _Step.register => _registerView(s),
              _Step.pending => _pendingView(s),
              _Step.vehicle => _vehicleView(s),
              _Step.trip => _tripView(s),
            },
          ),
        ),
        // Aviso tipo notificación push
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          top: _banner ? 10 : -120,
          left: 12,
          right: 12,
          child: Panel(
            color: surfaceHigh,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFD92D20), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('Acceso aprobado', 'Access approved'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(s.t('Ya puedes elegir tu vehículo.', 'You can now pick your vehicle.'), style: const TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(s.t('ahora', 'now'), style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _registerView(S s) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.t('Registro de conductor', 'Driver sign-up'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(s.t('La empresa revisa y aprueba tu acceso antes de manejar.', 'The company reviews and approves your access before you drive.'),
              style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: labInput(s.name),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v ?? '').trim().isEmpty ? s.nameRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rut,
            decoration: labInput(s.rut, helper: s.rutHelp),
            inputFormatters: [RutFormatter()],
            keyboardType: TextInputType.visiblePassword,
            validator: (v) => isValidRut(v ?? '') ? null : s.rutInvalid,
          ),
          const SizedBox(height: 24),
          LabButton(label: s.t('Solicitar acceso', 'Request access'), icon: Icons.send_rounded, onPressed: _register, color: const Color(0xFFF87171)),
          const SizedBox(height: 12),
          Text(s.demoNotice, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _pendingView(S s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 3200),
              builder: (context, v, _) => SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: v, strokeWidth: 6, backgroundColor: surfaceHigh, color: const Color(0xFFF87171)),
                    const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 40),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(s.t('Esperando aprobación', 'Waiting for approval'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${_name.text.trim()} · ${_rut.text}', style: const TextStyle(color: muted)),
            const SizedBox(height: 4),
            Text(s.t('Te avisaremos con una notificación.', "We'll let you know with a notification."), style: const TextStyle(color: muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _vehicleView(S s) {
    final q = normalizePlate(_search.text);
    final plates = _fleetPlates.where((p) => p.contains(q)).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.t('Hola, ${_name.text.trim().split(' ').first}', 'Hi, ${_name.text.trim().split(' ').first}'),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(s.t('¿Qué vehículo vas a manejar?', 'Which vehicle are you driving?'), style: const TextStyle(color: muted)),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          decoration: labInput(s.t('Buscar patente', 'Search plate'), suffix: const Icon(Icons.search_rounded)),
        ),
        const SizedBox(height: 12),
        if (plates.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.t('Sin resultados', 'No results'), textAlign: TextAlign.center, style: const TextStyle(color: muted)),
          ),
        for (final p in plates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _startTrip(p),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PlateView(text: formatPlate(p), scale: 0.55),
                      const SizedBox(width: 14),
                      Expanded(child: Text(s.t('Disponible', 'Available'), style: const TextStyle(color: muted))),
                      const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFF87171), size: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_trips.isNotEmpty) ...[
          const SizedBox(height: 16),
          LabLabel(s.t('Viajes registrados', 'Logged trips')),
          for (final t in _trips)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_rounded, color: accent),
              title: Text(formatPlate(t.plate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              trailing: Text(_clock(t.duration), style: const TextStyle(color: muted, fontFeatures: [FontFeature.tabularFigures()])),
            ),
        ],
      ],
    );
  }

  Widget _tripView(S s) {
    final elapsed = DateTime.now().difference(_start!);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Spacer(),
          PlateView(text: formatPlate(_plate!)),
          const SizedBox(height: 28),
          Text(s.t('Viaje en curso', 'Trip in progress'), style: const TextStyle(color: muted)),
          Text(_clock(elapsed),
              style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 8),
          Text('${_name.text.trim()} · ${_rut.text}', style: const TextStyle(color: muted)),
          const Spacer(),
          LabButton(label: s.t('Terminar viaje', 'End trip'), icon: Icons.stop_circle_rounded, onPressed: _endTrip, color: const Color(0xFFF87171)),
        ],
      ),
    );
  }
}

String _clock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}
