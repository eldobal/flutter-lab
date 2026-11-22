#!/usr/bin/env bash
# Compila Flutter Lab a WebAssembly y lo copia a public/flutter del portafolio.
set -euo pipefail
cd "$(dirname "$0")"
flutter build web --wasm --release --base-href /flutter/
rm -rf ../public/flutter
# El motor (canvaskit/skwasm) se descarga desde gstatic.com según engineRevision,
# así que la copia local (~24 MB) no se usa y no se despliega.
rsync -a --exclude '*.symbols' --exclude 'flutter_service_worker.js' --exclude 'canvaskit/' build/web/ ../public/flutter/
echo "Listo: public/flutter actualizado"
