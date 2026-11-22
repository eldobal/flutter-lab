import 'package:flutter/material.dart';

import '../../main.dart';
import 'booking_model.dart';

/// Plano del bus: la carrocería se dibuja con CustomPainter y cada asiento es un widget animado.
class SeatMap extends StatelessWidget {
  const SeatMap({super.key, required this.occupied, required this.selected, required this.onSelect});
  final Set<String> occupied;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 300.0);
        final seat = (width - 64) / 5; // 4 asientos + pasillo, con margen para la carrocería
        return Center(
          child: CustomPaint(
            painter: _BusPainter(),
            child: SizedBox(
              width: width,
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, seat * 1.4, 32, 26),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.driver, style: const TextStyle(color: muted, fontSize: 11)),
                            const SizedBox(width: 6),
                            const Icon(Icons.trip_origin_rounded, color: muted, size: 22),
                          ],
                        ),
                      ),
                    ),
                    for (var row = 1; row <= seatRows; row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var c = 0; c < seatCols.length; c++) ...[
                              if (c == 2)
                                SizedBox(
                                  width: seat,
                                  child: Text('$row', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
                                ),
                              _Seat(
                                id: '$row${seatCols[c]}',
                                size: seat,
                                taken: occupied.contains('$row${seatCols[c]}'),
                                selected: selected == '$row${seatCols[c]}',
                                onTap: onSelect,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.id, required this.size, required this.taken, required this.selected, required this.onTap});
  final String id;
  final double size;
  final bool taken;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final color = selected ? accent : (taken ? surfaceHigh : surface);
    return Semantics(
      button: !taken,
      selected: selected,
      label: '${s.seat} $id, ${taken ? s.seatTaken : (selected ? s.seatSelected : s.seatFree)}',
      child: GestureDetector(
        onTap: taken ? null : () => onTap(id),
        child: AnimatedScale(
          scale: selected ? 1.12 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.32),
                topRight: Radius.circular(size * 0.32),
                bottomLeft: Radius.circular(size * 0.16),
                bottomRight: Radius.circular(size * 0.16),
              ),
              border: Border.all(color: selected ? accent : (taken ? Colors.transparent : const Color(0xFF3A4252)), width: 1.5),
              boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 14)] : null,
            ),
            alignment: Alignment.center,
            child: taken
                ? const Icon(Icons.close_rounded, size: 14, color: Color(0xFF5A6273))
                : Text(id, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? ink : Colors.white70)),
          ),
        ),
      ),
    );
  }
}

/// Silueta del bus con parabrisas, espejos y ruedas.
class _BusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(14, 0, size.width - 28, size.height),
      topLeft: const Radius.circular(40),
      topRight: const Radius.circular(40),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );
    // Ruedas
    final wheel = Paint()..color = const Color(0xFF0B0D12);
    for (final y in [size.height * 0.18, size.height * 0.82]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, y - 22, 14, 44), const Radius.circular(6)), wheel);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 20, y - 22, 14, 44), const Radius.circular(6)), wheel);
    }
    // Espejos
    final mirror = Paint()..color = const Color(0xFF3A4252);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 30, 12, 26), const Radius.circular(5)), mirror);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 12, 30, 12, 26), const Radius.circular(5)), mirror);
    // Carrocería
    canvas.drawRRect(body, Paint()..color = const Color(0xFF13171E));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF2A3140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Parabrisas
    final glass = Path()
      ..moveTo(40, 22)
      ..quadraticBezierTo(size.width / 2, 6, size.width - 40, 22)
      ..lineTo(size.width - 46, 40)
      ..quadraticBezierTo(size.width / 2, 28, 46, 40)
      ..close();
    canvas.drawPath(glass, Paint()..color = accent.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(_BusPainter oldDelegate) => false;
}
