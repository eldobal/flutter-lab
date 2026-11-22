import 'dart:math';

/// Periféricos BLE simulados. La cerradura expone un servicio GATT propio con
/// características de estado (read/notify), comando (write) y batería (read).

const lockServiceUuid = '6e40a001-b5a3-f393-e0a9-e50e24dc0001';
const stateCharUuid = '6e40a002-b5a3-f393-e0a9-e50e24dc0001';
const commandCharUuid = '6e40a003-b5a3-f393-e0a9-e50e24dc0001';
const batteryCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';

class FakeDevice {
  FakeDevice(this.name, this.id, this.baseRssi, {this.isLock = false});
  final String name;
  final String id;
  final int baseRssi;
  final bool isLock;
  int rssi = -100;
  double angle = Random().nextDouble() * 2 * pi;

  /// RSSI con ruido, como en la realidad.
  void jitter(Random rand) => rssi = baseRssi + rand.nextInt(9) - 4;

  /// 0 = encima, 1 = borde del radar.
  double get distance => ((-rssi - 40) / 60).clamp(0.1, 1.0);
}

List<FakeDevice> nearbyDevices() => [
      FakeDevice('Cerradura-DEMO', 'C4:7F:51:0A:22:01', -52, isLock: true),
      FakeDevice('Sensor-Temp-07', 'E2:19:A0:33:5C:7D', -68),
      FakeDevice('Beacon-Bodega', 'F0:08:D1:92:4E:B3', -79),
      FakeDevice('Banda-Fit', 'D7:3A:6C:11:09:E8', -86),
    ];

class FakeLock {
  bool locked = true;
  int battery = 87;

  /// Valor de la característica de estado: 0x01 bloqueada, 0x00 desbloqueada.
  List<int> readState() => [locked ? 0x01 : 0x00];

  /// Escribe un comando: 0x01 bloquear, 0x00 desbloquear. Devuelve la notificación
  /// que emite la característica de estado, o null si el comando no es válido.
  List<int>? write(List<int> value) {
    if (value.length != 1 || (value[0] != 0x00 && value[0] != 0x01)) return null;
    locked = value[0] == 0x01;
    battery = max(0, battery - 1);
    return readState();
  }
}

String hex(List<int> bytes) => bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(' ');
