# Flutter Lab

App Flutter real que corre dentro del teléfono de mi portafolio: **[sebastianbaldovinos.com](https://sebastianbaldovinos.com)** (abre la app "Flutter Lab").
Se compila a WebAssembly y el portafolio la carga en un iframe solo cuando se abre la app.

> Este repositorio es la copia pública de la carpeta `flutter_lab/` del portafolio.

## Demos

Cada demo se inspira en un proyecto del portafolio. Todo usa datos ficticios.

- **Flota en vivo** · Rastreosat (`lib/demos/fleet/`): buses simulados por Santiago sobre un mapa real con `flutter_map` (OpenStreetMap en modo oscuro). Tocar un bus muestra velocidad, próxima parada, ETA y ocupación, y la cámara lo sigue.
- **Acceso de conductor** · MiAcceso (`lib/demos/access/`): registro con RUT, espera de aprobación con aviso tipo push, búsqueda de patente y cronómetro del viaje.
- **Lectura de patentes** · Control Sellos MEL (`lib/demos/ocr/`): cámara simulada con barrido, lectura carácter por carácter y corrección real de errores del OCR por posición (`fixOcrPlate` en `lib/plate.dart`).
- **Reserva de asientos** · SGT Reservas (`lib/demos/booking/`): ruta y horario, plano del bus con `CustomPainter`, datos del pasajero con RUT y pase de abordaje con QR que se da vuelta en 3D.
- **Control de embarque** · SGT Embarques (`lib/demos/embark/`): servicio y patente validada, registro por cédula o RUT, duplicados rechazados y modo sin conexión con sincronización.
- **Tótem de autoservicio** · SGT Tótem Fijo (`lib/demos/totem/`): teclado táctil para el RUT, asignación de asiento y comprobante de 58 mm (32 columnas) que sale de la impresora.
- **Cerradura Bluetooth** · POC BLE (`lib/demos/ble/`): escaneo con radar según RSSI, conexión, servicio GATT con características read/write/notify y bloqueo remoto con log.

El toggle iOS / Android del teléfono cambia `ThemeData.platform` en vivo vía `postMessage` (ver `lib/bridge.dart`).

## Correr y compilar

```bash
flutter run -d chrome                 # en desarrollo
./build_web.sh                        # dentro del portafolio: compila a wasm y copia a ../public/flutter
```

Cada demo se puede abrir directo con `?demo=<id>` (por ejemplo `/flutter/?demo=fleet`).

## Pruebas

```bash
flutter test                          # lógica (VM)
flutter test --platform chrome test/web   # recorre cada demo en Chrome
```
