import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../plate.dart';
import '../common.dart';

/// Inspirado en Control Sellos MEL: lectura de patentes con OCR y asignación de conductor.
/// La cámara se simula; la corrección de la lectura (O/0, S/5...) es lógica real (`fixOcrPlate`).
class OcrDemo extends StatefulWidget {
  const OcrDemo({super.key});

  @override
  State<OcrDemo> createState() => _OcrDemoState();
}

/// Patente real y lo que "leyó" el OCR, con sus errores típicos.
const _scenes = [
  (plate: 'LPRS56', raw: 'LPR556', color: Color(0xFFE5E7EB), driver: 'M. Rojas'),
  (plate: 'KR4521', raw: 'KR452I', color: Color(0xFF2563EB), driver: 'C. Pérez'),
  (plate: 'HJPT90', raw: 'HJPT9O', color: Color(0xFFDC2626), driver: 'J. Soto'),
  (plate: 'GHJK34', raw: '6HJK34', color: Color(0xFF16A34A), driver: 'A. Muñoz'),
];

class _OcrDemoState extends State<OcrDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  int _scene = 0;
  int _read = 0; // caracteres leídos
  bool _assigned = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  void _scan() {
    _timer?.cancel();
    setState(() {
      _read = 0;
      _assigned = false;
    });
    _sweep.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (_read >= 6) {
        t.cancel();
        _sweep.stop();
        setState(() {});
        return;
      }
      setState(() => _read++);
    });
  }

  void _next() {
    _scene = (_scene + 1) % _scenes.length;
    _scan();
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final scene = _scenes[_scene];
    final done = _read >= 6;
    final fixed = done ? fixOcrPlate(scene.raw) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Visor de cámara simulado
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 4 / 3.4,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _CarPainter(scene.color))),
                Align(
                  alignment: const Alignment(0, 0.42),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: done ? accent : Colors.white24, width: done ? 3 : 1.5),
                    ),
                    child: PlateView(text: formatPlate(scene.plate), scale: 0.8),
                  ),
                ),
                if (!done)
                  AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) => Align(
                      alignment: Alignment(0, -1 + _sweep.value * 2),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent,
                          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 2)],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(done ? Icons.check_circle_rounded : Icons.document_scanner_rounded, size: 14, color: done ? accent : Colors.white),
                        const SizedBox(width: 6),
                        Text(done ? s.t('Patente detectada', 'Plate detected') : s.t('Buscando patente…', 'Looking for a plate…'),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Lectura cruda del OCR, carácter por carácter
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabLabel(s.t('Lectura OCR', 'OCR reading')),
              Row(
                children: [
                  for (var i = 0; i < 6; i++)
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: i < _read ? 1 : 0.15,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: done && fixed != null && fixed[i] != scene.raw[i] ? const Color(0x33F59E0B) : surfaceHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(scene.raw[i], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                ],
              ),
              if (done && fixed != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.t('Corregido por posición: ${scene.raw} → ${formatPlate(fixed)}', 'Fixed by position: ${scene.raw} → ${formatPlate(fixed)}'),
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !done
              ? const SizedBox(key: ValueKey('wait'), height: 0)
              : Panel(
                  key: ValueKey('$_scene-$_assigned'),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: const Color(0xFF0F766E), child: Text(scene.driver[0], style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(scene.driver, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            Text(
                              _assigned ? s.t('Asignado a ${formatPlate(scene.plate)}', 'Assigned to ${formatPlate(scene.plate)}') : s.t('Conductor sugerido', 'Suggested driver'),
                              style: TextStyle(color: _assigned ? accent : muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (!_assigned)
                        TextButton(onPressed: () => setState(() => _assigned = true), child: Text(s.t('Asignar', 'Assign')))
                      else
                        const Icon(Icons.check_circle_rounded, color: accent),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        LabButton(label: s.t('Escanear otro vehículo', 'Scan another vehicle'), icon: Icons.camera_alt_rounded, onPressed: done ? _next : null, color: const Color(0xFF2DD4BF)),
        const SizedBox(height: 10),
        Text(s.t('La cámara es simulada. En la app real la lectura la hace Google ML Kit.', 'The camera is simulated. In the real app, Google ML Kit does the reading.'),
            textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

/// Parte trasera de un vehículo, dibujada a mano.
class _CarPainter extends CustomPainter {
  _CarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Fondo: estacionamiento de noche
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1F2937), Color(0xFF0B0F14)]).createShader(Offset.zero & size));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = const Color(0xFF111418));
    // Carrocería
    final body = Paint()..color = color;
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.14, w * 0.56, h * 0.34), Radius.circular(w * 0.08)), body);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.19, w * 0.44, h * 0.2), Radius.circular(w * 0.04)), Paint()..color = const Color(0xFF0F172A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.4, w * 0.8, h * 0.4), Radius.circular(w * 0.06)), body);
    canvas.drawRect(Rect.fromLTWH(w * 0.1, h * 0.72, w * 0.8, h * 0.08), shade);
    // Luces traseras
    final light = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.13, h * 0.46, w * 0.14, h * 0.07), const Radius.circular(6)), light);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.73, h * 0.46, w * 0.14, h * 0.07), const Radius.circular(6)), light);
    // Ruedas
    final tire = Paint()..color = const Color(0xFF050608);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.78, w * 0.12, h * 0.1), const Radius.circular(6)), tire);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h * 0.78, w * 0.12, h * 0.1), const Radius.circular(6)), tire);
  }

  @override
  bool shouldRepaint(_CarPainter oldDelegate) => oldDelegate.color != color;
}
