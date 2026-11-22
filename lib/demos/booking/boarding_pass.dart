import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../main.dart';
import 'booking_model.dart';

/// Pase de abordaje que se da vuelta en 3D al tocarlo: adelante el viaje, atrás el QR.
class BoardingPass extends StatefulWidget {
  const BoardingPass({super.key, required this.booking, this.startFlipped = false});
  final Booking booking;
  final bool startFlipped;

  @override
  State<BoardingPass> createState() => _BoardingPassState();
}

class _BoardingPassState extends State<BoardingPass> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: widget.startFlipped ? 1 : 0,
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() => _flip.isCompleted || _flip.velocity > 0 ? _flip.reverse() : _flip.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: CurvedAnimation(parent: _flip, curve: Curves.easeInOutBack),
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_flip.value);
          final angle = t * pi;
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _Back(booking: widget.booking),
                  )
                : _Front(booking: widget.booking),
          );
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2A44), Color(0xFF14181F)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF2E3A55)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final route = booking.route;
    const label = TextStyle(color: muted, fontSize: 12);
    const value = TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700);
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FlutterLogo(size: 22),
              const SizedBox(width: 8),
              Text(s.boardingPass.toUpperCase(), style: const TextStyle(color: accent, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
              const Spacer(),
              Text(booking.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _City(time: booking.time, city: route.from)),
              Column(
                children: [
                  const Icon(Icons.directions_bus_rounded, color: accent),
                  Text(s.duration(route.minutes), style: label),
                ],
              ),
              Expanded(child: _City(time: arrivalTime(booking.time, route.minutes), city: route.to, end: true)),
            ],
          ),
          const Spacer(),
          const _Perforation(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.passenger, style: label), Text(booking.name, style: value, overflow: TextOverflow.ellipsis)])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(s.seat, style: label), Text(booking.seat, style: value.copyWith(color: accent, fontSize: 24))]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(s.shortDate(booking.date), style: const TextStyle(color: Colors.white70))),
              Text(s.price(route.price), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _City extends StatelessWidget {
  const _City({required this.time, required this.city, this.end = false});
  final String time;
  final String city;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        Text(city, style: const TextStyle(color: muted, fontSize: 13), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Línea punteada con muescas a los lados, como un ticket de verdad.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 2, width: double.infinity, child: CustomPaint(painter: _DashPainter()));
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A4766)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 1), Offset(min(x + 5, size.width), 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

class _Back extends StatelessWidget {
  const _Back({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    return _Shell(
      child: Column(
        children: [
          Text(s.showAtBoarding, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: QrImageView(
              data: booking.qrPayload,
              size: 190,
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: ink),
            ),
          ),
          const Spacer(),
          Text('${s.code} ${booking.code} · ${s.seat} ${booking.seat}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ],
      ),
    );
  }
}
