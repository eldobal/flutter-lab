@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_lab/bridge.dart';
import 'package:flutter_lab/home.dart';
import 'package:flutter_lab/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recorre cada demo en un navegador real (usa package:web por el puente).
/// Correr con: flutter test --platform chrome test/web
void main() {
  Future<void> open(WidgetTester tester, String id) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FlutterLab(bridge: HostBridge()));
    await tester.pump();
    if (id == 'home') return;
    final demo = demos.firstWhere((d) => d.id == id);
    final context = tester.element(find.byType(HomePage));
    final (title, _) = demoTexts(LabScope.of(context).strings, id);
    await tester.scrollUntilVisible(find.text(title), 100);
    await tester.ensureVisible(find.text(title));
    await tester.pump();
    await tester.tap(find.text(title));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(demo.builder(context).runtimeType), findsOneWidget);
  }

  Future<void> wait(WidgetTester tester, int ms) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('home muestra los 7 demos', (tester) async {
    await open(tester, 'home');
    expect(demos, hasLength(7));
    expect(find.textContaining('Inspirada en'), findsWidgets);
  });

  testWidgets('MiAcceso: registro, aprobación y viaje', (tester) async {
    await open(tester, 'access');
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), '123456785');
    await tester.tap(find.text('Solicitar acceso'));
    await wait(tester, 3600);
    expect(find.text('Acceso aprobado'), findsOneWidget);
    await tester.tap(find.text('BC·DF·12'));
    await wait(tester, 1500);
    expect(find.text('Viaje en curso'), findsOneWidget);
    await tester.tap(find.text('Terminar viaje'));
    await wait(tester, 4000);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await wait(tester, 500);
    expect(find.text('VIAJES REGISTRADOS'), findsOneWidget);
  });

  testWidgets('Sellos MEL: lee, corrige y asigna', (tester) async {
    await open(tester, 'ocr');
    await wait(tester, 2200);
    expect(find.textContaining('LPR556 → LP·RS·56'), findsOneWidget);
    await tester.tap(find.text('Asignar'));
    await wait(tester, 500);
    expect(find.textContaining('Asignado a'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Escanear otro vehículo'), 100);
    await tester.tap(find.text('Escanear otro vehículo'));
    await wait(tester, 2200);
    expect(find.textContaining('KR452I'), findsOneWidget);
  });

  testWidgets('Embarques: patente, escaneo y modo sin conexión', (tester) async {
    await open(tester, 'embark');
    await tester.enterText(find.byType(TextField), 'XX');
    await tester.tap(find.text('Iniciar embarque'));
    await tester.pump();
    expect(find.textContaining('Patente inválida'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'bcdf12');
    await tester.tap(find.text('Iniciar embarque'));
    await wait(tester, 500);
    await tester.tap(find.text('Escanear cédula'));
    await wait(tester, 1500);
    expect(find.text('1/40'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await wait(tester, 400);
    await tester.enterText(find.byType(TextField), '111111111');
    await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
    await wait(tester, 500);
    expect(find.textContaining('1 pendientes'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await wait(tester, 1200);
    expect(find.text('1 registros sincronizados'), findsOneWidget);
  });

  testWidgets('Tótem: RUT inválido, válido y comprobante', (tester) async {
    await open(tester, 'totem');
    for (final k in '123456789'.split('')) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.text('Confirmar asiento'));
    await tester.pump();
    expect(find.text('RUT inválido'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Confirmar asiento'));
    await wait(tester, 3000);
    expect(find.text('Siguiente pasajero'), findsOneWidget);
  });

  testWidgets('BLE: escaneo, conexión y desbloqueo', (tester) async {
    await open(tester, 'ble');
    await wait(tester, 4000);
    expect(find.text('Banda-Fit'), findsOneWidget);
    await tester.tap(find.text('Cerradura-DEMO'));
    await wait(tester, 1600);
    expect(find.textContaining('Bloqueada'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await wait(tester, 1000);
    expect(find.textContaining('Desbloqueada'), findsOneWidget);
    expect(find.textContaining('NOTIFY state → 0x00'), findsOneWidget);
    // Detener el escaneo para que no queden timers vivos
    await tester.pumpWidget(const SizedBox());
  });
}
