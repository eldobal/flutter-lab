/// Comprobante de 58 mm (32 columnas), como el que imprime el tótem por ESC/POS.
const receiptWidth = 32;

String _center(String text) {
  final t = text.length > receiptWidth ? text.substring(0, receiptWidth) : text;
  final left = (receiptWidth - t.length) ~/ 2;
  return (' ' * left + t).padRight(receiptWidth);
}

String _row(String label, String value) {
  final space = receiptWidth - label.length - value.length;
  if (space < 1) return '$label ${value.substring(0, receiptWidth - label.length - 1)}';
  return '$label${' ' * space}$value';
}

List<String> buildReceipt({
  required String rut,
  required String route,
  required String date,
  required String time,
  required String seat,
  required String bus,
  required String code,
  required Map<String, String> labels,
}) {
  final line = '-' * receiptWidth;
  return [
    _center('TRANSPORTE DE PERSONAL'),
    _center(labels['title']!),
    line,
    _row(labels['rut']!, rut),
    _row(labels['route']!, route),
    _row(labels['date']!, date),
    _row(labels['time']!, time),
    _row(labels['bus']!, bus),
    line,
    _center('${labels['seat']!} $seat'),
    line,
    _center(code),
    _center(labels['footer']!),
  ];
}
