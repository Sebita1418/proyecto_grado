# Transporte Inteligente — entrega académica F-DC-125

**Cierre: 16 de octubre de 2026, America/Bogota.** Autores: Brayan Emerson Jurado Quintero y Joan Sebastian Camacho Gualdron. Directora: Carmen Cecilia Dulcey López.

Este índice consolida los cortes históricos sin atribuir a un APK funciones probadas solo en un diagnóstico o en el servidor. El texto literal del objetivo aprobado y el título institucional completo siguen pendientes de cotejo con el F-DC-124 original. No se inventan ni se sustituyen.

## Acceso principal

- [Trazabilidad final: funcionalidades, pruebas, versiones y originales](08-publicacion-final/TRAZABILIDAD.md).
- [Texto técnico para incorporar al F-DC-125](08-publicacion-final/FDC125-TEXTO-TECNICO.md).
- [Publicación, acceso privado y distribución del APK](08-publicacion-final/ENTREGA.md).
- [Inventario exacto de los archivos versionados](08-publicacion-final/INVENTARIO.md).
- [Validación real TomTom desde sesión Flutter](04-objetivo-3/tomtom-flutter-session-20261016/README.md): captura, JSON, CSV, cuota y rechazo sin Auth.
- [Procesamiento histórico, OSRM y pruebas del corte D](04-objetivo-3/objective-3-final-verification.md). Este informe fue anterior a la prueba remota: su estado BLOCKED de TomTom fue resuelto por el corte enlazado arriba; conserva sus límites de ranking.
- [Adaptación API sin Docker](04-objetivo-3/tomtom-api-bundle-20261016/README.md).

## Resultados y separación de ambientes

| Ambiente / artefacto | Evidencia aprobada | Límite |
|---|---|---|
| APK académico 1.0.2 / 2026101601 | Compilación, firma Debug, tres assets, instalación/apertura de componente S22 y hash instalado/restaurado | Tráfico deshabilitado; no atribuirle la pantalla de diagnóstico ni nuevas selecciones Google |
| Código del corte objetivo 3 | 769 Flutter y 6 Node aprobadas; 9 consultas OSRM, 14 alternativas; 39.193 registros recibidos, 39.190 válidos, 3 descartados | Fixtures y replay se rotulan; no ahorros reales ni Big Data completo |
| Bundle de traffic-flow | 11 Node aprobadas; geometrías originales idénticas; JWT/cuota preservados | Prueba local distinta de ejecución remota |
| Diagnóstico temporal Flutter + Supabase | Sesión activa verificada; HTTP 200 TomTom; 51/51 km/h, confianza 1; 23:32:16 Bogotá, 1.581 ms; cuota 0→1, límite 10; sin Auth HTTP 401 | Un punto/instante de Bucaramanga; no cobertura general, no ranking/ETA ajustado |

## APK conservado

`transporte-inteligente-1.0.2-2026101601-release-debug-signed.apk`, **60.331.195 bytes**. SHA-256:

`435913b6c1eb08ace49d80005f7b20d4561a1428fa9d254ba45a769384d9eb40`.

Release académica, firma Android Debug, aplicación `com.example.transporte_inteligente`, minSdk 24, targetSdk 36. No es firma de producción. No se recompiló para este cierre. La ficha original está en [version.json](04-objetivo-3/intervention-2026-10-16/version.json); manifiesto de fuentes de construcción en el mismo directorio. El commit de publicación también contiene trabajos posteriores del servidor y el diagnóstico, que no se presentan como incluidos en ese APK.

## Historia, privacidad e integridad

- [Cortes A/B/C y trazabilidad histórica](01-trazabilidad/README.md), [pruebas anteriores](02-pruebas-automatizadas/README.md) y [matriz Android histórica](03-pruebas-android/README.md).
- [Matriz Android del APK 1.0.2](04-objetivo-3/intervention-2026-10-16/android-matrix.md): conservar NOT TESTED donde no existe observación específica. La prueba de servidor/diagnóstico no aprueba navegación física ni OAuth nuevo.
- [Videos originales: manifiesto local, no publicados](05-videos-originales/README.md).
- [Capturas derivadas revisadas](06-capturas/README.md); la captura TomTom es original y no contiene cuentas.
- [Sellos históricos](07-integridad-y-versiones/README.md). El índice anterior se conserva byte a byte en [snapshot del corte C](08-publicacion-final/indice-maestro-original-corte-c.md); su hash histórico corresponde a ese snapshot, no al índice actualizado. No se reescriben los logs ni sellos anteriores.

El repositorio permanece privado. Los videos originales con cuentas/conversaciones y los fotogramas de revisión sin anonimizar quedan excluidos de Git y Release. Acceso de evaluadora: ver ENTREGA; no se otorgan permisos ni se cambia visibilidad automáticamente.

No se declara Big Data completo, reducción observada de tiempos, hora óptima por corredor, ganador multimodal ni cobertura general TomTom. Tráfico actual todavía no altera ranking o duración OSRM.

## Publicación efectiva

- [PR #58 hacia develop](https://github.com/Sebita1418/proyecto_grado/pull/58), abierto y sin fusionar.
- [Release académica privada](https://github.com/Sebita1418/proyecto_grado/releases/tag/academic-20261016-v1.0.2).
- [Descarga directa del APK 1.0.2](https://github.com/Sebita1418/proyecto_grado/releases/download/academic-20261016-v1.0.2/transporte-inteligente-1.0.2-2026101601-release-debug-signed.apk), verificada mediante descarga autenticada y SHA-256.
- [Acta completa de publicación y assets](08-publicacion-final/PUBLICACION.json).

El cierre reejecutó analyze sin incidencias, **769 Flutter y 13 Node aprobadas**, sin fallos ni omitidas: [FINAL-QA.json](08-publicacion-final/FINAL-QA.json). No son pruebas de un APK nuevo: se distribuye el binario conservado. Sin merge ni cambio de visibilidad; la evaluadora necesita acceso de lectura.
