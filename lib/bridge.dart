import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Puente con la página que contiene el iframe (el teléfono del portafolio).
///
/// La página puede cambiar la plataforma y el idioma sin recargar Flutter con
/// `postMessage({ type: 'flutter-lab', platform: 'ios' | 'android', lang: 'es' | 'en' })`.
class HostBridge {
  HostBridge() {
    final params = Uri.base.queryParameters;
    platform.value = params['platform'] == 'android' ? TargetPlatform.android : TargetPlatform.iOS;
    lang.value = params['lang'] == 'en' ? 'en' : 'es';
    web.window.addEventListener('message', _onMessage.toJS);
  }

  final platform = ValueNotifier<TargetPlatform>(TargetPlatform.iOS);
  final lang = ValueNotifier<String>('es');

  void _onMessage(web.MessageEvent event) {
    // Solo aceptamos mensajes de la misma página que nos aloja
    if (event.origin != web.window.location.origin) return;
    final data = event.data.dartify();
    if (data is! Map || data['type'] != 'flutter-lab') return;
    final p = data['platform'];
    if (p == 'ios') platform.value = TargetPlatform.iOS;
    if (p == 'android') platform.value = TargetPlatform.android;
    final l = data['lang'];
    if (l == 'es' || l == 'en') lang.value = l as String;
  }

  /// Avisa a la página que Flutter ya pintó su primer frame (para ocultar la carga).
  void notifyReady() {
    web.window.parent?.postMessage({'type': 'flutter-lab-ready'}.jsify(), web.window.location.origin.toJS);
  }

  /// Abre un enlace en una pestaña nueva (por ejemplo, el código en GitHub).
  void openUrl(String url) => web.window.open(url, '_blank', 'noopener');
}
