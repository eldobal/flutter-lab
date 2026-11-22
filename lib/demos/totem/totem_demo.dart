import 'dart:math';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../rut.dart';
import '../../strings.dart';
import '../common.dart';
import 'receipt.dart';

/// Inspirado en SGT Tótem Fijo: el pasajero digita su RUT en un teclado táctil,
/// el sistema le asigna su asiento y el tótem "imprime" un comprobante de 58 mm.
class TotemDemo extends StatefulWidget {
  const TotemDemo({super.key});

  @override
  State<TotemDemo> createState() => _TotemDemoState();
}

const _purple = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFA78BFA);

class _TotemDemoState extends State<TotemDemo> {
  String _digits = '';
  bool _loading = false;
  List<String>? _receipt;
  String? _error;

  String get _rut => _digits.length < 2 ? _digits : formatRut(_digits);

  void _press(String key) {
    setState(() {
      _error = null;
      if (key == '⌫') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else if (_digits.length < 9) {
        _digits += key;
      }
    });
  }

  Future<void> _confirm(S s) async {
    if (!isValidRut(_digits)) {
      setState(() => _error = s.rutInvalid);
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final rand = Random(_digits.hashCode);
    final now = DateTime.now();
    setState(() {
      _loading = false;
      _receipt = buildReceipt(
        rut: _rut,
        route: ['Faena Norte', 'Planta Sur', 'Campamento'][rand.nextInt(3)],
        date: '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
        time: '${(now.hour + 1) % 24}:${['00', '15', '30', '45'][rand.nextInt(4)]}',
        seat: '${1 + rand.nextInt(10)}${'ABCD'[rand.nextInt(4)]}',
        bus: 'BUS-${100 + rand.nextInt(60)}',
        code: 'SGT-${1000 + rand.nextInt(9000)}',
        labels: {
          'title': s.t('COMPROBANTE DE ASIENTO', 'SEAT RECEIPT'),
          'rut': 'RUT',
          'route': s.t('Ruta', 'Route'),
          'date': s.t('Fecha', 'Date'),
          'time': s.t('Salida', 'Departs'),
          'bus': 'Bus',
          'seat': s.t('ASIENTO', 'SEAT'),
          'footer': s.t('Buen viaje', 'Have a good trip'),
        },
      );
    });
  }

  void _reset() => setState(() {
        _digits = '';
        _receipt = null;
      });

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _receipt == null ? _keypadView(s) : _receiptView(s, _receipt!),
    );
  }

  Widget _keypadView(S s) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'K', '0', '⌫'];
    return Padding(
      key: const ValueKey('keypad'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(s.t('Ingresa tu RUT para confirmar tu asiento', 'Enter your RUT to confirm your seat'),
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(_rut.isEmpty ? '— — — — —' : _rut,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _rut.isEmpty ? muted : Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(s.rutHelp, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final keyHeight = min(64.0, (c.maxHeight - 3 * 10) / 4);
                return GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: (c.maxWidth - 20) / 3 / keyHeight,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final k in keys)
                      Material(
                        color: k == '⌫' || k == 'K' ? surfaceHigh : surface,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _press(k),
                          child: Center(
                            child: k == '⌫'
                                ? const Icon(Icons.backspace_outlined, color: Colors.white)
                                : Text(k, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          LabButton(label: s.t('Confirmar asiento', 'Confirm seat'), icon: Icons.event_seat_rounded, loading: _loading, onPressed: _digits.length >= 2 ? () => _confirm(s) : null, color: _purpleLight),
        ],
      ),
    );
  }

  Widget _receiptView(S s, List<String> lines) {
    return ListView(
      key: const ValueKey('receipt'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.print_rounded, color: _purpleLight),
            const SizedBox(width: 8),
            Expanded(child: Text(s.t('Imprimiendo comprobante…', 'Printing receipt…'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 12),
        // Ranura de la impresora y el papel saliendo
        Container(height: 10, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5), border: Border.all(color: _purple, width: 2))),
        ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => Align(alignment: Alignment.bottomCenter, heightFactor: v, child: child),
            child: Center(
              child: Container(
                width: 270,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAF7),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: FittedBox(
                  child: Column(children: [for (final l in lines) _MonoLine(l)]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        LabButton(label: s.t('Siguiente pasajero', 'Next passenger'), icon: Icons.person_rounded, onPressed: _reset, color: _purpleLight),
        const SizedBox(height: 10),
        Text(s.t('En el tótem real se imprime por USB con ESC/POS (canal nativo en Kotlin).', 'On the real kiosk it prints over USB with ESC/POS (native Kotlin channel).'),
            textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

/// Flutter web no trae fuentes del sistema: cada carácter va en una celda de ancho fijo
/// para que el comprobante se vea monoespaciado como en la impresora térmica.
class _MonoLine extends StatelessWidget {
  const _MonoLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in text.padRight(receiptWidth).split(''))
          SizedBox(
            width: 8,
            height: 17,
            child: Center(child: Text(ch, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600))),
          ),
      ],
    );
  }
}
