import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'demo_page.dart';
import 'demos/access/access_demo.dart';
import 'demos/ble/ble_demo.dart';
import 'demos/booking/booking_demo.dart';
import 'demos/embark/embark_demo.dart';
import 'demos/ocr/ocr_demo.dart';
import 'demos/totem/totem_demo.dart';
import 'demos/fleet/fleet_demo.dart';
import 'main.dart';
import 'strings.dart';

class Demo {
  const Demo({required this.id, required this.icon, required this.color, required this.file, required this.project, required this.builder});
  final String id;
  final IconData icon;
  final Color color;
  final String file;
  /// Proyecto del portafolio en el que se inspira el demo
  final String project;
  final WidgetBuilder builder;
}

// Mismo orden que los proyectos del portafolio
final demos = [
  Demo(id: 'fleet', icon: Icons.map_rounded, color: const Color(0xFF3B5BDB), file: 'demos/fleet/fleet_demo.dart', project: 'Rastreosat', builder: (_) => const FleetDemo()),
  Demo(id: 'access', icon: Icons.badge_rounded, color: const Color(0xFFD92D20), file: 'demos/access/access_demo.dart', project: 'MiAcceso', builder: (_) => const AccessDemo()),
  Demo(id: 'ocr', icon: Icons.document_scanner_rounded, color: const Color(0xFF0F766E), file: 'demos/ocr/ocr_demo.dart', project: 'Control Sellos MEL', builder: (_) => const OcrDemo()),
  Demo(id: 'booking', icon: Icons.directions_bus_rounded, color: const Color(0xFF1D4ED8), file: 'demos/booking/booking_demo.dart', project: 'SGT Reservas', builder: (_) => const BookingDemo()),
  Demo(id: 'embark', icon: Icons.how_to_reg_rounded, color: const Color(0xFFD99E00), file: 'demos/embark/embark_demo.dart', project: 'SGT Embarques', builder: (_) => const EmbarkDemo()),
  Demo(id: 'totem', icon: Icons.point_of_sale_rounded, color: const Color(0xFF7C3AED), file: 'demos/totem/totem_demo.dart', project: 'SGT Tótem Fijo', builder: (_) => const TotemDemo()),
  Demo(id: 'ble', icon: Icons.bluetooth_rounded, color: const Color(0xFF0EA5E9), file: 'demos/ble/ble_demo.dart', project: 'POC Bluetooth BLE', builder: (_) => const BleDemo()),
];

(String, String) demoTexts(S s, String id) => switch (id) {
      'fleet' => (s.fleetTitle, s.fleetDesc),
      'access' => (s.t('Acceso de conductor', 'Driver access'), s.t('Registro con RUT, aprobación con aviso push y registro del viaje.', 'RUT sign-up, push-style approval and trip logging.')),
      'ocr' => (s.t('Lectura de patentes', 'Plate reading'), s.t('OCR simulado con corrección real de errores y asignación de conductor.', 'Simulated OCR with real error correction and driver assignment.')),
      'embark' => (s.t('Control de embarque', 'Boarding control'), s.t('Registro de pasajeros por cédula o RUT, con modo sin conexión.', 'Passenger check-in by ID card or RUT, with offline mode.')),
      'totem' => (s.t('Tótem de autoservicio', 'Self-service kiosk'), s.t('Teclado táctil, asignación de asiento y comprobante térmico.', 'Touch keypad, seat assignment and a thermal receipt.')),
      'ble' => (s.t('Cerradura Bluetooth', 'Bluetooth lock'), s.t('Escaneo BLE con radar, servicio GATT y bloqueo remoto.', 'BLE scan with radar, GATT service and remote locking.')),
      _ => (s.bookingTitle, s.bookingDesc),
    };

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // `?demo=fleet` abre un demo directamente (enlaces desde el portafolio)
    final id = Uri.base.queryParameters['demo'];
    final demo = demos.where((d) => d.id == id).firstOrNull;
    if (demo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final (title, _) = demoTexts(LabScope.of(context).strings, demo.id);
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DemoPage(demo: demo, title: title)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _FlutterBadge(),
            const SizedBox(height: 14),
            Text(s.subtitle, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white)),
            const SizedBox(height: 14),
            const _PlatformCard(),
            const SizedBox(height: 18),
            for (final demo in demos) ...[
              _DemoTile(demo: demo, isIOS: isIOS),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlutterBadge extends StatelessWidget {
  const _FlutterBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FlutterLogo(size: 30),
        const SizedBox(width: 10),
        Text(LabScope.of(context).strings.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
}

/// Muestra en qué plataforma está renderizando la app; cambia en vivo con el toggle del teléfono.
class _PlatformCard extends StatelessWidget {
  const _PlatformCard();

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation), child: child),
            ),
            child: Row(
              key: ValueKey(isIOS),
              children: [
                Icon(isIOS ? CupertinoIcons.device_phone_portrait : Icons.android_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                Text(isIOS ? 'iOS · Cupertino' : 'Android · Material 3',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                const Spacer(),
                Switch.adaptive(value: true, onChanged: (_) {}),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(s.platformHint, style: const TextStyle(color: muted, fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.demo, required this.isIOS});
  final Demo demo;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    final s = LabScope.of(context).strings;
    final (title, desc) = demoTexts(s, demo.id);
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DemoPage(demo: demo, title: title))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Hero(
                tag: 'icon-${demo.id}',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: demo.color, borderRadius: BorderRadius.circular(isIOS ? 12 : 24)),
                  child: Icon(demo.icon, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(color: muted, fontSize: 13, height: 1.3)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: demo.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s.basedOn(demo.project),
                          style: TextStyle(color: Color.lerp(demo.color, Colors.white, 0.45), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Icon(isIOS ? CupertinoIcons.chevron_forward : Icons.arrow_forward_rounded, color: muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
