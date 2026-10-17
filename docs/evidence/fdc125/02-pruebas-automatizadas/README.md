# Pruebas automatizadas: ejecución original del 16/10/2026

**754 aprobadas, 0 fallidas, 0 omitidas**. Conteos calculados desde eventos testDone no ocultos; skipped separado. No se reutilizaron conteos antiguos. Estado del código: 15e672c04262b4b4d40175334cd784ab9f26ad283166495f90a924c36ec1ac69. Flutter 3.47.7 stable (abaf9c5237), Dart 3.13.5. Rama feature/android-end-to-end-validation, base 226f1a4fb04fcc8b5bc8a2aed4e7e4a550b71fa4 más cambios sin commit.

| Comando | Inicio UTC | Duración s | Código |
|---|---|---|---|
| flutter analyze --no-pub | 2026-10-17T01:41:45.9988455Z | 127.994 | 0 |
| flutter test --no-pub --machine | 2026-10-17T01:43:54.0021192Z | 86.638 | 0 |
| git diff --check | 2026-10-17T01:45:20.6399290Z | 0.219 | 0 |

Las horas UTC del 17/10 corresponden a la noche del 16/10 en Bogotá (UTC−05). No confundir fecha UTC con fecha académica local. El analizador informa internamente 120,9 s; commands.json mide también arranque/salida de proceso.

- [Comandos y tiempos originales](commands.json).
- [Resumen calculado](run-summary.json).
- [Resultado de cada test con nombre y archivo](tests-results.json).
- [Salida original del análisis](analyze-original.log) y [copia UTF-8 legible](analyze-readable.txt).
- [Salida original machine](test-machine-original.log) y [copia UTF-8](test-machine-readable.jsonl).
- [Diff original](diff-original.log).
- [Identidad del código](../01-trazabilidad/code-state.json) y [archivos sin commit](../01-trazabilidad/git-status-before.txt).

Los .log originales de PowerShell conservan su codificación; las copias legibles solo cambian codificación, no resultados. [Proveniencia](encoding-provenance.json). El directorio de escenarios se redirigió con OE3_EVIDENCE_DIR para no sobrescribir el JSON original del 15/10.

Para reproducir en una nueva carpeta, con mismo inventario, SDK y dependencias disponibles:

    $env:OE3_EVIDENCE_DIR="docs/evidence/fdc125/04-objetivo-3/reproduccion-local"
    flutter analyze --no-pub
    flutter test --no-pub --machine
    git diff --check

Las suites cubren OAuth, cámara/GPS, GIS, geocodificación, recomendaciones, horarios y módulos existentes. Automatizado/mocks no equivale a GPS, OAuth o backend físico. La [matriz Android](../03-pruebas-android/README.md) usa estados separados.
