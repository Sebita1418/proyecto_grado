# Corte D: intervención objetivo 3, 16 de octubre de 2026

Acta principal: [objective-3-final-verification.md](../objective-3-final-verification.md).

Separación de evidencia:

- **A, observaciones externas:** `provider-requests.json` y nueve cuerpos
  `real-1..3-{driving,walking,cycling}.json`: respuestas OSRM capturadas una vez,
  con URL, fecha, SHA, tiempos y 14 alternativas. TomTom está BLOCKED sin key,
  con cero solicitudes; no se interpreta como ausencia de cobertura local.
- **B, controladas:** `tests-machine-final.log` conserva la suite original;
  `flutter-test-results.json`: 769 PASS/0 FAIL/0 SKIP. `node-tests.log`: 6 PASS.
  `comparisons.json/csv` identifica cada fixture y cada replay de bytes reales.
  `scenarios.json`: 12 casos de auditoría anteriores reejecutados. Los primeros
  intentos fallidos permanecen disponibles; los archivos finales están rotulados.
- **C, históricos observados:** `historical-source.json`, metadatos y hashes,
  `historical-analysis.json`, `historical-groups.csv`, descartes y log.
  Fuente Alcaldía de Bucaramanga / Datos Abiertos Colombia, 7cci-nqqb,
  licencia CC BY-SA 4.0 para fuente y derivados. 39.193 recibidos, 39.190 válidos,
  3 descartados. Siniestros 2012–2023, no tráfico actual ni riesgo ajustado.
- **D, Android:** instalación y apertura de componente por ADB registradas,
  hash instalado idéntico al APK nuevo; pantalla bloqueada, funciones pendientes
  según `android-observation.json` y [AND-01..10](android-matrix.md).

`version.json`, `source-state.sha256` y `source-delta.json` relacionan código,
pruebas y APK 1.0.2+2026101601. `integrity.json` sella los archivos de este corte;
no modifica el sello anterior. `preservation.json` y
`previous-evidence-seal-verification.json` comprueban originales previos y los
dos APK anteriores. `log-encoding-provenance.json` relaciona originales
PowerShell y copias UTF-8 legibles, sin editar sus resultados.

El proxy preparado en `supabase/` no fue desplegado y su SQL no se aplicó.
El APK usa firma Android Debug y tráfico externo deshabilitado: demostración
académica, no distribución de producción ni funcionalidad de congestión validada.

El literal aprobado del objetivo F-DC-124 y la comprobación humana de las
funciones del nuevo APK siguen pendientes; no se atribuyen al corte los videos
de otra versión. Sin commit, push, PR, cambios de lock, stash ni credenciales.
