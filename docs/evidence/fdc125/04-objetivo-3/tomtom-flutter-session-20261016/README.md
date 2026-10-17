# PASS: TomTom remoto usando la sesión activa de Flutter

Fecha local: **16 de octubre de 2026, 23:32, America/Bogota**.
Proyecto `zdjhqcarmmdgdfzuxhgv`. Dispositivo Samsung S22 SM-S901U,
R3CT30HX60V, Android 15/API 35.

**Resultado observado: sesión válida, HTTP 200, datos reales de TomTom y cuota
0 → 1.** Este corte resuelve el bloqueo de autenticación de la verificación
anterior. No sustituye ni reescribe los registros históricos de intentos previos.

## Prueba realizada y resultados

Se ejecutó un entrypoint manual aislado, `lib/traffic_probe_main.dart`, dentro
del mismo paquete Android de Transporte Inteligente. Supabase recuperó la
sesión existente del almacenamiento habitual; se comprobó `currentSession`,
vigencia y `auth.getUser()`. No hubo contraseña, selección nueva de cuenta,
extracción/copias manuales del JWT ni alteración del flujo Google OAuth.
El SDK gestionó internamente la autenticación de `client.functions.invoke`.

Solo después de validar la sesión se habilitó el botón **Consultar TomTom una
vez**. Se observó una única pulsación/solicitud; el botón queda deshabilitado y
no hay reintentos automáticos. El diagnóstico usó
`--dart-define=TRAFFIC_PROXY_ENABLED=true`. La coordenada pública elegida fue
Parque Santander, Bucaramanga: **7.1196763, -73.1228536**, tomada de la referencia
OSM conservada y aceptada por la geocerca de la función.

| Medida real | Resultado |
|---|---|
| `currentSession` presente, vigente y usuario validado por Auth | PASS, true |
| Estado HTTP de `traffic-flow` | **200** |
| Disponibilidad de datos TomTom | **true** |
| Fecha de inicio en dispositivo, UTC | 2026-10-17T04:32:15.166276Z |
| `queriedAt` devuelto por servidor, UTC | **2026-10-17T04:32:16.804Z** |
| Fecha del servidor en Bogotá | **2026-10-16 23:32:16.804 −05:00** |
| Latencia total medida por el cliente | **1.581 ms** |
| `currentSpeed`, km/h | **51** |
| `freeFlowSpeed`, km/h | **51** |
| `currentTravelTime`, segundos del fragmento | **828** |
| `freeFlowTravelTime`, segundos del fragmento | **828** |
| `confidence`, escala del proveedor | **1** |
| Cuota habilitada / límite diario | **true / 10** |
| Contador antes / después | **0 / 1** |
| Solicitudes restantes en ese día UTC | **9** |
| Petición posterior sin autenticación | **401**, 716 ms |

`queriedAt` identifica la consulta del proveedor, no el timestamp individual de
cada medición subyacente. La latencia es del cliente al endpoint completo,
incluyendo red, Auth, cuota y proveedor; no es latencia aislada de TomTom.
El día de cuota es UTC: `2026-10-17`, aunque en Bogotá aún era el día 16.

## Evidencia auténtica

- [remote-validation.json](remote-validation.json): resumen comprobado de sesión,
  datos reales, cuota, rechazo sin Auth y restauración del APK.
- [flutter-safe-events.log](flutter-safe-events.log): exclusivamente eventos
  `TOMTOM_PROBE_SAFE` con campos permitidos; no es un volcado de sesión o logs
  generales del teléfono.
- [Captura original del S22](s22-real-traffic.png): pantalla real del diagnóstico
  con HTTP 200, métricas y botón deshabilitado; inspeccionada visualmente.
- [quota-before.log](quota-before.log) y [quota-after.log](quota-after.log): lecturas
  SQL remotas mediante CLI autenticada y Management API; sin cambios SQL.
- [unauthenticated-check.json](unauthenticated-check.json): solicitud sin tokens,
  rechazada; el contador posterior continuó en uno.
- [academic-restored.json](academic-restored.json): restauración y hash instalado.
- [preservation.json](preservation.json): 118 archivos anteriores sin cambios,
  incluidos código productivo existente, GeoJSON, cuota, handler y tres APK.

No se guardaron cabeceras, JWT, refresh tokens, claves, IDs de usuario ni correos.
La respuesta se filtró deliberadamente a los campos permitidos; no se conserva
el cuerpo completo ni las coordenadas del fragmento retornado por TomTom.
La sesión Google existente fue reutilizada según la configuración del usuario;
esta prueba no acredita una nueva selección de cuenta ni un callback OAuth nuevo.

## Alcance y límites para el F-DC-125

Esta observación **sí demuestra integración remota de datos actuales reales de
TomTom desde Flutter autenticado**, con consumo controlado y rechazo básico sin
autenticación. No es un mock ni un dato del conjunto histórico de siniestros.
La cuota incrementó exactamente una vez tras una invocación autenticada y un
rechazo sin credenciales.

La velocidad actual coincide con la de flujo libre: **no se observó reducción
de velocidad en esta muestra**. No se afirma ausencia de congestión en toda
Bucaramanga ni cobertura de Girón, Floridablanca o cada vía. No se midieron
desplazamientos humanos ni ahorro real. Confianza 1 es un valor del proveedor,
no una garantía de exactitud, carril, sentido o correspondencia con OSRM.

Los 828 segundos son del **fragmento del proveedor**, no del viaje completo ni
un ETA OSRM. No se verificó aquí su asociación geométrica/direccional con una
alternativa de ruta. El ranking vehicular, sus reglas de incidentes, las
comparaciones entre modos y el historial permanecen sin cambios. Activar la
consulta no convierte el motor en un recomendador basado en congestión.

El dataset oficial de siniestros 2012–2023, sus agregados y las pruebas controladas
de recomendaciones siguen siendo evidencia separada. Esta llamada no demuestra
historial por corredor, horario óptimo, Big Data ni predicción de tráfico.

Frase sustentada para el informe: «Se verificó una consulta autenticada desde
Flutter a una Edge Function de Supabase integrada con TomTom Traffic Flow en un
punto de Bucaramanga, obteniendo velocidades actual y de flujo libre de 51 km/h,
confianza 1 y HTTP 200, con consumo de una unidad de una cuota diaria de diez».

## Compilación temporal y protección de la entrega

Análisis del entrypoint: **PASS, sin incidencias** en
`probe-analyze-final.log`. Compilación temporal: **PASS**, salida nativa 0,
`temporary-build-command.json`. No se volvió a ejecutar la suite completa y
no se atribuyen a este diagnóstico los recuentos de suites de cortes anteriores.

```powershell
flutter build apk --release --no-pub --target lib/traffic_probe_main.dart --build-name=1.0.2 --build-number=2026101601 --dart-define=TRAFFIC_PROXY_ENABLED=true
```

El artefacto temporal está en `artifacts/tomtom-flutter-session/`, ignorado por
Git, y se identifica por su SHA en `temporary-artifact.json`. No se copió a
`deliveries/` ni se presenta como APK académico definitivo. Se conservó
deliberadamente el mismo paquete/versión para preservar sesión y poder
reinstalar la entrega sin desinstalar ni borrar datos. Su identidad real se
distingue por target diagnóstico, contenido y hash.

Tras capturar la evidencia se reinstaló y abrió **el APK académico original**:

`deliveries/objective-3-intervention-20261016/transporte-inteligente-1.0.2-2026101601-release-debug-signed.apk`

SHA del archivo y del APK reinstalado:
`435913b6c1eb08ace49d80005f7b20d4561a1428fa9d254ba45a769384d9eb40`.
El académico sigue con tráfico deshabilitado y **no se le atribuye esta pantalla
de diagnóstico**. No hubo APK definitivo nuevo, commit, push o publicación.

El primer `flutter run` rechazó argumentos de versión antes de instalar o
consultar; se usó después `flutter build apk` temporal y ADB. El primer análisis
detectó cuatro avisos de llaves, corregidos antes de compilar. Los registros se
conservan sin reinterpretar esos intentos como PASS.

Para habilitarlo en una entrega posterior hará falta otro APK con flag true y
versión propia. Mínimos: comprobar `RouteTrafficService` con la geometría real,
rechazo de muestras antiguas/poco confiables o ajenas, errores/429/timeout,
una consulta acotada desde el flujo de rutas y su explicación, conservación de
selección/ruta, cuota y regresiones; luego firma, SHA, instalación y observación
en S22. **No hace falta cambiar el ranking para demostrar la consulta** y no se
cambió en este trabajo.
