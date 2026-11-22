import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bridge.dart';
import 'home.dart';
import 'strings.dart';

/// Flutter Lab: una app Flutter real que vive dentro del teléfono del portafolio.
void main() {
  final bridge = HostBridge();
  runApp(FlutterLab(bridge: bridge));
  WidgetsBinding.instance.addPostFrameCallback((_) => bridge.notifyReady());
}

const accent = Color(0xFF7CF29C);
const ink = Color(0xFF0F1218);
const surface = Color(0xFF181C24);
const surfaceHigh = Color(0xFF232935);
const muted = Color(0xFF9AA3B2);

/// Código público de cada demo (repo eldobal/flutter-lab, copia de esta carpeta; ver scripts/publicar-flutter-lab.sh).
const repoBase = 'https://github.com/eldobal/flutter-lab/blob/main/lib/';

class FlutterLab extends StatelessWidget {
  const FlutterLab({super.key, required this.bridge, this.navigatorKey});
  final HostBridge bridge;

  /// Solo lo usa el benchmark (`lib/bench.dart`) para abrir y cerrar demos.
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([bridge.platform, bridge.lang]),
      builder: (context, _) {
        final platform = bridge.platform.value;
        return LabScope(
          bridge: bridge,
          strings: S(bridge.lang.value),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Flutter Lab',
            // Con `platform` Flutter cambia transiciones, scroll y widgets adaptativos
            theme: ThemeData(
              brightness: Brightness.dark,
              platform: platform,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: accent,
                brightness: Brightness.dark,
                primary: accent,
                surface: ink,
              ),
              scaffoldBackgroundColor: ink,
              // En web Flutter siempre usa la flecha de Android; la adaptamos a la plataforma elegida
              actionIconTheme: ActionIconThemeData(
                backButtonIconBuilder: (context) =>
                    Icon(platform == TargetPlatform.iOS ? CupertinoIcons.back : Icons.arrow_back_rounded),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: ink,
                surfaceTintColor: Colors.transparent,
                centerTitle: platform == TargetPlatform.iOS,
              ),
            ),
            home: const HomePage(),
          ),
        );
      },
    );
  }
}

/// Da acceso al puente y a los textos desde cualquier widget.
class LabScope extends InheritedWidget {
  const LabScope({super.key, required this.bridge, required this.strings, required super.child});
  final HostBridge bridge;
  final S strings;

  static LabScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LabScope>()!;

  @override
  bool updateShouldNotify(LabScope oldWidget) => strings.lang != oldWidget.strings.lang;
}
