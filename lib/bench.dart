import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

import 'bridge.dart';
import 'demo_page.dart';
import 'home.dart';
import 'main.dart';
import 'strings.dart';

/// Benchmark de navegación entre demos. No es parte de la app publicada:
///
///   flutter build web --wasm --release -t lib/bench.dart --base-href /flutter-bench/
///
/// Abre y cierra cada demo en automático y mide, por fase (animación de entrada, montaje, en uso, salir):
/// - `frames` / `p95` / `max`: duración de cada frame de Flutter (build + raster, ms).
/// - `gaps`: huecos entre requestAnimationFrame del navegador > 20 ms (frames perdidos).
/// El resultado queda en `window.benchResult` (JSON) y en la consola.
const _mount = Duration(milliseconds: 450); // justo después: primer build del demo
const _inUse = Duration(milliseconds: 2000);
const _exit = Duration(milliseconds: 700);

final _navigator = GlobalKey<NavigatorState>();
final _frames = <(double start, double ms)>[]; // en ms de performance.now()
final _rafs = <double>[];
bool _recording = true;

double _now() => web.window.performance.now();

void main() {
  final bridge = HostBridge();
  runApp(FlutterLab(bridge: bridge, navigatorKey: _navigator));
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      // En web los timestamps de FrameTiming salen de performance.now() en microsegundos
      _frames.add((t.timestampInMicroseconds(FramePhase.vsyncStart) / 1000, t.totalSpan.inMicroseconds / 1000));
    }
  });
  void raf(JSNumber ts) {
    _rafs.add(ts.toDartDouble);
    if (_recording) web.window.requestAnimationFrame(raf.toJS);
  }

  web.window.requestAnimationFrame(raf.toJS);
  Future<void>.delayed(const Duration(seconds: 3), _run);
}

/// Espera a que la animación de entrada de la ruta termine.
Future<void> _entered(ModalRoute<void> route) {
  final a = route.animation!;
  if (a.status == AnimationStatus.completed) return Future.value();
  final done = Completer<void>();
  void listener(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      a.removeStatusListener(listener);
      done.complete();
    }
  }

  a.addStatusListener(listener);
  return done.future;
}

Future<void> _run() async {
  final marks = <(String, double, double)>[];
  Future<void> phase(String name, Future<void> Function() wait) async {
    final start = _now();
    await wait();
    marks.add((name, start, _now()));
  }

  Future<void> Function() delay(Duration d) => () => Future<void>.delayed(d);

  const s = S('es');
  for (final demo in demos) {
    final (title, _) = demoTexts(s, demo.id);
    final route = MaterialPageRoute<void>(builder: (_) => DemoPage(demo: demo, title: title));
    _navigator.currentState!.push(route);
    // La fase "anim" termina exactamente cuando la ruta completa su transición de entrada.
    // Justo después de push la ruta aún no se instala (reporta `completed`): esperar un frame.
    await phase('${demo.id}.anim', () => SchedulerBinding.instance.endOfFrame.then((_) => _entered(route)));
    await phase('${demo.id}.mount', delay(_mount));
    await phase('${demo.id}.use', delay(_inUse));
    _navigator.currentState!.pop();
    await phase('${demo.id}.exit', delay(_exit));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  // Las timings llegan en lotes: esperar el último
  await Future<void>.delayed(const Duration(milliseconds: 500));
  _recording = false;

  final result = <String, Object>{};
  for (final (name, a, b) in marks) {
    final ms = [for (final (t, d) in _frames) if (t >= a && t < b) d]..sort();
    final rafs = [for (final t in _rafs) if (t >= a && t < b) t];
    var gaps = 0;
    var worstGap = 0.0;
    for (var i = 1; i < rafs.length; i++) {
      final g = rafs[i] - rafs[i - 1];
      if (g > 20) gaps++;
      worstGap = max(worstGap, g);
    }
    double r(double v) => (v * 10).round() / 10;
    result[name] = {
      'ms': (b - a).round(),
      'frames': ms.length,
      'p95': ms.isEmpty ? 0 : r(ms[min(ms.length - 1, (ms.length * 0.95).floor())]),
      'max': ms.isEmpty ? 0 : r(ms.last),
      'gaps': gaps,
      'worstGap': r(worstGap),
    };
  }
  final json = jsonEncode(result);
  web.console.log('BENCH $json'.toJS);
  (web.window as JSObject).setProperty('benchResult'.toJS, json.toJS);
}
