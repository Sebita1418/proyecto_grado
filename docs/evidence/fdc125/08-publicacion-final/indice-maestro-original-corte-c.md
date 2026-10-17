# Transporte Inteligente — evidencias de subsanación F-DC-125

**Autores:** Brayan Emerson Jurado Quintero y Joan Sebastian Camacho Gualdron.  
**Directora:** Carmen Cecilia Dulcey López.  
**Fecha de consolidación:** 16 de octubre de 2026, America/Bogota.  
**Finalidad:** aportar evidencia original, ejecutada y reproducible del software y del procesamiento/recomendaciones del objetivo específico 3.

El nombre confirmado del proyecto es **Transporte Inteligente**. El título institucional completo y el objetivo 3 literal del F-DC-124 no están disponibles en el repositorio: se solicitaron al usuario y quedan pendientes de contraste, sin inventar una redacción aprobada.

## Índice navegable

1. [Trazabilidad, versiones A/B/C y estado sin commit](01-trazabilidad/README.md).
2. [Pruebas automatizadas: comandos, resultados y originales](02-pruebas-automatizadas/README.md).
3. [Pruebas Android AND-01..AND-10 y límites de observación](03-pruebas-android/README.md).
4. [Matriz de los 12 casos ejecutados del objetivo 3](04-objetivo-3/README.md) y [diagrama técnico](04-objetivo-3/flow.md).
5. [Videos originales: manifiesto y revisión pendiente de privacidad](05-videos-originales/README.md).
6. [Capturas complementarias anonimizadas y proveniencia](06-capturas/README.md).
7. [Integridad, APK final y reproducción](07-integridad-y-versiones/README.md).
8. [Procedimiento GitHub preparado, no ejecutado](01-trazabilidad/PUBLICACION.md).
9. [Inventario navegable de cada archivo de evidencia](07-integridad-y-versiones/INVENTARIO.md).

## Evidencia y alcance

La ejecución nueva del 16/10 obtiene **754 aprobadas, 0 fallidas y 0 omitidas**, análisis sin incidencias y diff correcto. Las salidas originales, tiempos UTC, códigos de salida y nombres de cada prueba están en la sección 02. Las horas UTC del 17/10 corresponden a la noche del 16/10 en Bogotá; no se cambió el reloj ni la fecha de los registros.

El corte A del 14/10 reportó 742 pruebas y produjo APK 1.0.0/20261014. El corte B del 15/10 reportó 754 pruebas, sin generar APK nuevo. El corte C del 16/10 tiene inventario propio, prueba reejecutada y versión final 1.0.1/20261016. **No son artefactos intercambiables ni se atribuyen los 754 tests retrospectivamente al APK A.** Véase la tabla de versiones.

- **Automatizadas:** ejecutan componentes reales con assertions y controles de regresión. Mocks HTTP y fixtures se identifican explícitamente.
- **Simuladas/deterministas:** las rutas, incidentes y series históricas de los 12 casos son entradas sintéticas; no son mediciones de tráfico ni inserciones Supabase de producción.
- **Observación real:** los videos aportados muestran interacciones visibles de una aplicación; no identifican hash/versionCode. Se revisaron fotogramas muestreados, no el audio ni todos los frames. La apertura A en S22 se documentó el 14/10 mediante ADB y captura.
- **Nueva validación física C:** no ejecutada; el S22 no estaba conectado el 16/10. Compilar no acredita Google real, GPS ni rutas en el teléfono.

Los originales se preservan con nombre, tamaño y SHA-256. Las capturas son **derivadas y enmascaradas**, no reemplazos de originales. Los videos incluyen cuentas y conversaciones privadas: están excluidos de Git y no deben adjuntarse a una publicación sin revisión y autorización específica. No se subió ningún archivo ni se cambiaron permisos del repositorio.

## Reproducción

Desde la raíz del proyecto, con Flutter 3.47.7/Dart 3.13.5 y paquetes existentes:

```powershell
$env:OE3_EVIDENCE_DIR='docs/evidence/fdc125/04-objetivo-3/reproduccion-local'
flutter analyze --no-pub
flutter test --no-pub --machine
git diff --check
```

Usar una carpeta nueva de salida para no sobrescribir evidencias originales. La identidad del código está en [code-state.json](01-trazabilidad/code-state.json) y [source-state.sha256](01-trazabilidad/source-state.sha256), incluyendo archivos todavía sin commit. El commit base por sí solo no reproduce el working tree probado. La [sección 07](07-integridad-y-versiones/README.md) documenta los argumentos exactos de compilación y la firma.

## Limitaciones y pendientes

El modelo vehicular es determinista y explicable, con personalización limitada a contexto y elegibilidad por modos locales. Hay routing por tres modos, pero no un recomendador conjunto entre medios. El historial describe reportes generales, no una hora óptima por corredor. No hay Big Data masivo, aprendizaje por usuario, predicción ni proveedor de congestión en vivo. No se ha certificado configuración remota de RPC/RLS/Realtime ni cumplimiento integral del OE3 literal.

Pendientes institucionales: texto aprobado del F-DC-124, título completo y aceptación del alcance por la directora. Pendientes operativos: identidad/versionado de los clips, revisión de privacidad/audio, flujos físicos de C y autorización posterior para commit/push/PR/Release y acceso de la directora. El repositorio continúa privado.

## Fuentes consolidadas sin reescribir registros históricos

- [Auditoría de objetivo 3](../../objective-3-validation.md) y [ejecución histórica del 15/10](../objective-3/2026-10-15/run-summary.json).
- [Validación APK A](../../android-release-validation.md).
- [Direcciones y navegación](../../address-and-navigation-audit.md).
- [Cobertura operativa](../../operational-coverage.md) y [límite territorial](../../municipal-boundary.md).
- [Inventario inicial de originales](07-integridad-y-versiones/originals-baseline.json).

Los manifiestos y sus SHA-256 prueban integridad de archivos, no veracidad independiente de lo filmado ni eficacia del sistema en la movilidad urbana.
