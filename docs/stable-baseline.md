# Baseline de estabilización — 2026-09-25

Rama: `feature/explainable-mobility-recommendation`. La baseline es el commit
que incorpora este documento, posterior a `d671f37` de `origin/develop`.

## Integración y B8

Último merge incorporado: `d671f37`, experiencia de mapa v2 (#35). También se
integran `189cd0a` (#33, B8 vehicular explicable) y `2b537ac` (#34, recuperación
del flujo de demostración). La actualización fue fast-forward, sin reescribir
historia ni modificar develop remoto.

El borrador B8 local previo se conserva íntegro en el stash
`d6a4390a8aea0f64da528b9ea7dd2aca47228f08`, incluidos archivos no versionados
en su tercer padre. No aplicar ese stash completo sobre esta baseline:
implementa otra política de desempate, selección y preferencias, y duplicaría
el motor y los mensajes de la recomendación ya integrada.

Se conserva un solo motor productivo, `VehicleRecommendationEngine`: duración,
distancia ante empate y orden del proveedor ante empate completo. B8 está
integrado con preferencias, selección inicial explicada, elección manual y
protección frente a respuestas obsoletas. Se rescata del borrador la validación
de extremos: ninguna candidata de otro viaje puede ser recomendada. No se
añaden tráfico, horarios, costos, emisiones ni datos de disponibilidad.

## Correcciones

- 19 fallos de la suite del merge: búsquedas de tooltips anteriores y pulsación
  de un botón fuera del área visible. Se actualizan las expectativas y el scroll,
  conservando las comprobaciones de navegación, accesibilidad y cálculo.
- Validación de origen/destino en el motor y prueba que rechaza ambos desajustes.
  Los fixtures de concurrencia/GPS usan ahora extremos del cálculo vigente.
- Texto de preferencias alineado con B8: se aplican al volver a calcular.
- Permiso Internet en el manifiesto principal Android para el flujo de red en release.

## Validación

- Flutter 3.47.2 / Dart 3.13.2; `flutter pub get` correcto, lockfile sin cambios.
  Doce paquetes presentan versiones posteriores fuera de las restricciones
  actuales; no se actualizan dependencias sin necesidad de integración.
- `flutter analyze --no-pub`: sin incidencias.
- 51 pruebas específicas de B8, preferencias y flujo de rutas aprobadas.
- `flutter test --no-pub --reporter expanded`: 260 pruebas aprobadas, salida 0.
- `flutter build web --release --no-pub --no-wasm-dry-run`: generado `build/web`.
  También completó la comprobación Wasm del primer build; no se ejecutó la app en Wasm.
- `dart format` en archivos modificados y `git diff --check`.

No se acredita aceptación manual ni servicios remotos reales con tests de dobles.
Android SDK no está instalado y falta Visual Studio para Windows: los builds
nativos quedan sin validar por herramientas del entorno, no por un error de
compilación demostrado. La firma Android sigue usando configuración de desarrollo.

## Deuda diferida y continuación

- Proveedores públicos del prototipo, infraestructura gestionada y disponibilidad.
- Aceptación real de autenticación/Supabase, RLS y GPS; casos manuales de
  `demo-acceptance.md` permanecen pendientes.
- Dependencia Google Maps heredada, preferencias por instalación, firma de
  distribución y toolchains nativos.
- Backend de novedades, puntos cercanos con fuente real, horarios y multimodalidad;
  requisitos FDC pendientes de contraste. B8 no acredita estos alcances.

Siguiente incremento concreto: selección manual de ubicación en el mapa para
el borrador de «Reportar novedad vial», con marcador editable y coordenadas
confirmadas. Mantener explícito que no se publica hasta disponer del backend.

Continuar con comprobación Git mínima → implementación funcional/UI → pruebas
específicas → validación final → commit → push. No repetir auditoría integral
salvo evidencia concreta de conflicto de integración o regresión general.
