import 'package:flutter/material.dart';

import 'home.dart';
import 'main.dart';

/// Pantalla de un demo: barra con el ícono (Hero) y el enlace al código en GitHub.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.demo, required this.title});
  final Demo demo;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scope = LabScope.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'icon-${demo.id}',
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: demo.color, borderRadius: BorderRadius.circular(isIOS ? 7 : 14)),
                child: Icon(demo.icon, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: scope.strings.viewCode,
            icon: const Icon(Icons.code_rounded),
            onPressed: () => scope.bridge.openUrl('$repoBase${demo.file}'),
          ),
        ],
      ),
      body: AfterTransition(builder: demo.builder),
    );
  }
}

/// Construye el contenido recién cuando termina la animación de entrada de la ruta.
///
/// Así la transición (y el Hero del ícono) corre sola, sin competir con el primer
/// build del demo, sus mapas, timers y animaciones infinitas. Después entra con un fade corto.
class AfterTransition extends StatefulWidget {
  const AfterTransition({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<AfterTransition> createState() => _AfterTransitionState();
}

class _AfterTransitionState extends State<AfterTransition> {
  Animation<double>? _route;
  bool _checked = false;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    final route = ModalRoute.of(context);
    if (route == null) {
      _ready = true;
      return;
    }
    // En el primer build la transición aún no arranca y la animación reporta `completed`:
    // el estado real se lee un frame después.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = route.animation;
      if (animation == null || animation.status == AnimationStatus.completed) {
        setState(() => _ready = true);
      } else {
        _route = animation..addStatusListener(_onStatus);
      }
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _route?.removeStatusListener(_onStatus);
    _route = null;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.expand();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Builder(builder: widget.builder),
    );
  }
}
