import '../../rut.dart';

/// Registro de embarque de un bus: valida RUT, evita duplicados y guarda
/// pendientes cuando no hay conexión, para sincronizarlos después.

enum AddResult { added, invalid, duplicate, full }

class Boarded {
  Boarded(this.rut, this.name, {required this.synced});
  final String rut;
  final String name;
  bool synced;
}

class BoardingSession {
  BoardingSession({required this.service, required this.plate, this.capacity = 40});
  final String service;
  final String plate;
  final int capacity;
  final List<Boarded> passengers = [];
  bool online = true;

  int get pending => passengers.where((p) => !p.synced).length;

  AddResult add(String rut, String name) {
    if (!isValidRut(rut)) return AddResult.invalid;
    final clean = formatRut(rut.replaceAll(RegExp(r'[^0-9kK]'), ''));
    if (passengers.any((p) => p.rut == clean)) return AddResult.duplicate;
    if (passengers.length >= capacity) return AddResult.full;
    passengers.insert(0, Boarded(clean, name, synced: online));
    return AddResult.added;
  }

  /// Marca como enviados los registros pendientes; devuelve cuántos se sincronizaron.
  int sync() {
    if (!online) return 0;
    var n = 0;
    for (final p in passengers.where((p) => !p.synced)) {
      p.synced = true;
      n++;
    }
    return n;
  }
}
