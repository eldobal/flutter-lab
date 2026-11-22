import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../plate.dart';
import '../../rut.dart';
import '../../strings.dart';
import '../common.dart';
import 'embark_model.dart';

/// Inspirado en SGT Embarques: el operador elige el servicio, ingresa la patente del bus
/// y registra a cada pasajero que sube, aunque se caiga la conexión.
class EmbarkDemo extends StatefulWidget {
  const EmbarkDemo({super.key});

  @override
  State<EmbarkDemo> createState() => _EmbarkDemoState();
}

const _services = ['Faena Norte · 06:30', 'Planta Sur · 07:15', 'Campamento · 19:00'];
const _names = ['Valentina Rojas', 'Diego Fuentes', 'Camila Araya', 'Matías Contreras', 'Fernanda Vera', 'Benjamín Castro', 'Javiera Núñez', 'Tomás Reyes'];

class _EmbarkDemoState extends State<EmbarkDemo> {
  final _rand = Random();
  String _service = _services.first;
  final _plate = TextEditingController();
  final _rut = TextEditingController();
  String? _plateError;
  BoardingSession? _session;
  bool _scanning = false;

  @override
  void dispose() {
    _plate.dispose();
    _rut.dispose();
    super.dispose();
  }

  void _start(S s) {
    if (!isValidPlate(_plate.text)) {
      setState(() => _plateError = s.t('Patente inválida (ej: BCDF12 o AB1234)', 'Invalid plate (e.g. BCDF12 or AB1234)'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _plateError = null;
      _session = BoardingSession(service: _service, plate: normalizePlate(_plate.text));
    });
  }

  void _add(S s, String rut, String name) {
    final result = _session!.add(rut, name);
    final msg = switch (result) {
      AddResult.added => null,
      AddResult.invalid => s.rutInvalid,
      AddResult.duplicate => s.t('Ese pasajero ya subió', 'That passenger already boarded'),
      AddResult.full => s.t('El bus está lleno', 'The bus is full'),
    };
    setState(() {});
    if (msg != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
    } else {
      _rut.clear();
    }
  }

  Future<void> _scan(S s) async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _scanning = false);
    _add(s, rutFromNumber(8000000 + _rand.nextInt(17000000)), _names[_rand.nextInt(_names.length)]);
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _session!.online = value);
    if (value && _session!.pending > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      final n = _session!.sync();
      setState(() {});
      final s = LabScope.of(context).strings;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.t('$n registros sincronizados', '$n records synced')), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return _session == null ? _setup(s) : _boarding(s, _session!);
  }

  Widget _setup(S s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.t('Nuevo embarque', 'New boarding'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        LabLabel(s.t('Servicio', 'Service')),
        for (final sv in _services)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _service = sv),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _service == sv ? const Color(0x33F5B700) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _service == sv ? const Color(0xFFF5B700) : const Color(0xFF2A3140)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route_rounded, color: _service == sv ? const Color(0xFFF5B700) : muted),
                    const SizedBox(width: 10),
                    Text(sv, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        LabLabel(s.t('Patente del bus', 'Bus plate')),
        TextField(
          controller: _plate,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() => _plateError = null),
          decoration: labInput('BCDF12').copyWith(errorText: _plateError),
        ),
        const SizedBox(height: 16),
        Center(child: PlateView(text: _plate.text.isEmpty ? '··  ··  ··' : formatPlate(_plate.text), scale: 0.8)),
        const SizedBox(height: 24),
        LabButton(label: s.t('Iniciar embarque', 'Start boarding'), icon: Icons.login_rounded, onPressed: () => _start(s), color: const Color(0xFFF5B700)),
      ],
    );
  }

  Widget _boarding(S s, BoardingSession session) {
    final count = session.passengers.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    PlateView(text: formatPlate(session.plate), scale: 0.5),
                    const SizedBox(width: 12),
                    Expanded(child: Text(session.service, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    Text('$count/${session.capacity}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: count / session.capacity),
                    duration: const Duration(milliseconds: 350),
                    builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: surfaceHigh, color: const Color(0xFFF5B700)),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(session.online ? Icons.wifi_rounded : Icons.wifi_off_rounded, size: 18, color: session.online ? accent : Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.online
                            ? s.t('En línea', 'Online')
                            : s.t('Sin conexión · ${session.pending} pendientes', 'Offline · ${session.pending} pending'),
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                    Switch.adaptive(value: session.online, onChanged: _toggleOnline),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rut,
                  inputFormatters: [RutFormatter()],
                  keyboardType: TextInputType.visiblePassword,
                  decoration: labInput(s.rut, helper: s.rutHelp),
                  onSubmitted: (v) => _add(s, v, s.t('Ingreso manual', 'Manual entry')),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: surfaceHigh, minimumSize: const Size(52, 52)),
                  onPressed: () => _add(s, _rut.text, s.t('Ingreso manual', 'Manual entry')),
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LabButton(
            label: _scanning ? s.t('Leyendo cédula…', 'Reading ID card…') : s.t('Escanear cédula', 'Scan ID card'),
            icon: Icons.credit_card_rounded,
            loading: _scanning,
            onPressed: () => _scan(s),
            color: const Color(0xFFF5B700),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: count == 0
              ? Center(child: Text(s.t('Aún no sube nadie', 'Nobody has boarded yet'), style: const TextStyle(color: muted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: count,
                  itemBuilder: (context, i) {
                    final p = session.passengers[i];
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(p.rut),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child)),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: surfaceHigh, child: Text('${count - i}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(p.rut, style: const TextStyle(color: muted)),
                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: p.synced
                              ? const Icon(Icons.cloud_done_rounded, key: ValueKey(true), color: accent)
                              : const Icon(Icons.cloud_upload_rounded, key: ValueKey(false), color: Colors.orangeAccent),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
