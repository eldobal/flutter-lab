import 'package:flutter/material.dart';

import '../main.dart';

/// Piezas visuales compartidas por los demos.

class LabButton extends StatelessWidget {
  const LabButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false, this.color});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: color ?? accent,
        foregroundColor: ink,
        disabledBackgroundColor: surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator.adaptive(strokeWidth: 2.5))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 6)],
                Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              ],
            ),
    );
  }
}

class LabLabel extends StatelessWidget {
  const LabLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A3140)),
      ),
      child: child,
    );
  }
}

/// Placa patente chilena dibujada (fondo blanco, borde negro, tipografía ancha).
class PlateView extends StatelessWidget {
  const PlateView({super.key, required this.text, this.scale = 1});
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14 * scale, 6 * scale, 14 * scale, 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.black, width: 3 * scale),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('CHILE', style: TextStyle(color: Colors.black87, fontSize: 8 * scale, letterSpacing: 4 * scale, fontWeight: FontWeight.w700)),
          Text(text, style: TextStyle(color: Colors.black, fontSize: 30 * scale, fontWeight: FontWeight.w900, letterSpacing: 2 * scale, height: 1.1)),
        ],
      ),
    );
  }
}

InputDecoration labInput(String label, {String? helper, Widget? suffix}) => InputDecoration(
      labelText: label,
      helperText: helper,
      suffixIcon: suffix,
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
