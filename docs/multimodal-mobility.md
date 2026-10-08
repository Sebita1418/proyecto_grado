# Movilidad multimodal productiva

## Baseline y decisión de alcance

Rama `feature/multimodal-mobility`, baseline `99a0eda`,
`feat: add mobility recommendation validation (#51)`. Se comprobó árbol limpio,
rama y diff check antes de modificar. No se hicieron commit, push, PR, SQL ni
cambios remotos en Supabase.

| Modo | Capacidad configurada | Disponibilidad de una consulta | Recomendación | Navegación guiada |
|---|---|---|---|---|
| Vehículo | OSRM existente | Solo tras respuesta real válida | VehicleRecommendationEngine existente | Navigation V2 existente |
| A pie | FOSSGIS routed-foot | Solo tras respuesta real válida | No se aplica motor vehicular | No habilitada |
| Bicicleta | FOSSGIS routed-bike | Solo tras respuesta real válida | No se aplica motor vehicular | No habilitada |
| Transporte público | Sin proveedor integrado | UNAVAILABLE | No disponible | No disponible |

Una capacidad permite solicitar una ruta; no certifica disponibilidad actual.
Antes de consultar se muestra UNKNOWN («Sin consultar: proveedor configurado»).
Solo una respuesta con ruta real produce AVAILABLE y métricas. No hay tiempos
derivados del automóvil, rutas reetiquetadas ni datos productivos de ejemplo.

## Auditoría y verificación del proveedor

El baseline declara `OsrmConfig.endpoint = https://router.project-osrm.org` y
`OsrmRoutingService` usa `/route/v1/driving/{coordinates}`. El enum de modos no
prueba capacidades del servidor. Cambiar únicamente `driving` por `walking` o
`cycling` no certifica que haya grafos adecuados; este incremento utiliza
instancias con paths de backend separados.

Fuentes primarias consultadas el 7 de octubre de 2026:

- [FOSSGIS: servidores, perfiles y condiciones](https://routing.openstreetmap.de/about.html).
- [OSRM: servidor de demostración](https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server).
- [Configuración oficial del frontend FOSSGIS](https://raw.githubusercontent.com/fossgis-routing-server/osrm-frontend/master/src/leaflet_options.js).

El frontend identifica `routed-car`, `routed-bike` y `routed-foot` como servicios
distintos. FOSSGIS documenta cobertura mundial por modo. Se verificaron mediante
GET los endpoints foot y bike con las coordenadas públicas del ejemplo oficial
de Berlín, sin transmitir ubicación del usuario:

| Backend | code | Distancia devuelta | Duración devuelta |
|---|---|---|---|
| routed-foot | Ok | 3323.9 m | 2658.1 s |
| routed-bike | Ok | 3106.5 m | 1117.1 s |

Consulta: origen `13.414167165756226,52.52167215019524`; destino
`13.4197763,52.5003103`, orden longitud/latitud. Se usó
`/route/v1/driving/{coordinates}?overview=false&steps=false` en cada backend.
El segmento `driving` conserva el protocolo usado por el frontend; el grafo
de modo se determina por `routed-foot` o `routed-bike`. Esos datos solo documentan
verificación, no se incorporan al código productivo como rutas de muestra.
La prueba no certifica toda la cobertura colombiana ni disponibilidad permanente.

La primera verificación con coordenadas de Bucaramanga fue bloqueada por revisión
automática por posible exposición de ubicación. La comprobación aprobada usó
exclusivamente el ejemplo público de Berlín. No se eludió el rechazo enviando
el payload original por otra vía.

## Arquitectura y routing real

`RoutingRequest(origin, destination, mode)` → `ModeRoutingService` → instancia
OSRM del grafo correcto → `RouteResult` del proveedor → panel/mapa.
La composición conserva la inyección de `OsrmRoutingService` y sus métodos
`route`/`routeAlternatives`, por lo que los mocks vehiculares existentes siguen
siendo utilizables. No se agregó un parámetro obligatorio a sus overrides.

`RoutingCapabilities` enumera modos configurados. `ModeRouteSummary` contiene
estado, causa, métricas recibidas, proveedor, número de alternativas y causa
tipada de error. `MultimodalMobilitySnapshot` es un mapa inmutable por modo y
representa evidencia descriptiva de los mismos endpoints dentro del panel.
Editar endpoints o invalidar el cálculo elimina esas comparaciones anteriores.

Los endpoints nuevos son:

```text
walking: https://routing.openstreetmap.de/routed-foot
cycling: https://routing.openstreetmap.de/routed-bike
driving: https://router.project-osrm.org (sin cambiar)
```

Se conserva protocolo HTTP, timeout, alternativas en orden del proveedor,
geometría GeoJSON validada, métricas finitas no negativas y parsing de steps.
No se ajustan distancia, duración ni geometría. Un modo no soportado falla antes
de hacer HTTP. Cada instancia permite cliente/endpoint inyectados para tests.

Errores internos: unsupported, unavailable (p.ej. HTTP no exitoso), networkError,
timeout, noRoute (code NoRoute) e invalidResponse. Un payload Ok sin rutas se
considera respuesta inválida. La UI distingue resultados UNKNOWN, AVAILABLE,
UNAVAILABLE y ERROR; no convierte red fallida en cero métricas.

## Condiciones de demo y privacidad

FOSSGIS limita el uso a consultas razonables, exige atribución y enlace de
corrección del mapa, identificación de cliente y máximo una petición por
segundo. Las instancias OSRM comparten una cola local con separación mínima de
1100 ms para los hosts públicos FOSSGIS/OSRM. Se incluye User-Agent identificable;
en navegador las cabeceras controladas por el navegador siguen sus restricciones.
El resultado incluye atribución OpenStreetMap y enlaces a copyright/fixthemap.

La limitación se aplica dentro del proceso, no es una cuota global entre todos
los dispositivos. No hay scraping ni precarga masiva de los cuatro modos.
Se consulta el modo seleccionado. Una demo de pocos usuarios es el alcance;
despliegue público masivo necesita infraestructura administrada y límites
centrales. No hay SLA de disponibilidad, latencia ni actualidad de datos.

El proveedor recibe origen y destino al solicitar la ruta, y su política indica
registro de solicitudes en servidor. No se envían UUID, correo, nombre, reportes
individuales ni credenciales Supabase en routing. No se guarda historial de
rutas multimodales en Supabase. Las métricas y geometrías permanecen en el estado
del flujo existente.

`url_launcher` 6.3.2 ya estaba instalado como dependencia transitiva de
`flutter_map`; se declaró directo y fijado a la misma versión para los enlaces
de atribución. No se añadieron SDKs de pago, claves ni otro motor de routing.

## Experiencia de modo y estados

El selector conserva cuatro tarjetas visibles, iconos, tema y disposición
responsive. Los callers antiguos sin capacidades siguen mostrando la UI
vehicular anterior; el flujo productivo inyecta capacidades/snapshots explícitos.
La UI no deduce disponibilidad solo porque exista un valor en TransportMode.

Seleccionar un modo consultable con una ruta existente solicita una nueva ruta
usando exactamente sus endpoints, sin re-geocodificar ni modificar los textos.
Hay indicador de carga y la ruta conservada se identifica por su modo mientras
se consulta. Si falla, el resultado/selección anteriores se conservan y se
publica el error del modo intentado. No se aplica la respuesta de un cálculo
obsoleto si cambian los endpoints o se destruye el panel.

Los modos sin proveedor no llaman routing. Transporte público muestra:
«Sin fuente de datos de transporte público integrada». El repositorio no tiene
GTFS/API transit compatible; no se añadieron líneas, paradas ni horarios.

Las preferencias guardadas se comprueban antes de routing al cambiar de modo
y al calcular inicialmente walking/cycling. Sin preferencias, el usuario puede
elegir explícitamente el modo consultable. El comportamiento por defecto continúa
siendo vehículo. No se introduce un ranking global entre medios.

## Reportes, recomendación y navegación

Vehículo conserva el motor determinista, snapshots de reportes, RouteInsight,
alternativas, selección manual, validación de recomendación y Navigation V2.
La única adaptación de OSRM común es identificación, límite de demo y errores
tipados; no se alteran pesos, métricas ni reglas vehiculares.

Walking/cycling muestran rutas, alternativas, comparación de duración/distancia
dentro del modo y selección manual. No ejecutan VehicleRecommendationEngine,
no muestran su recomendación incident-aware, ni aplican automáticamente los
reportes vehiculares al recorrido. Se muestra esa limitación explícitamente.
El panel no ofrece validación vehicular sobre una ruta no vehicular.

NavigationProgress es geométrico y el modelo de instrucciones es compartido,
pero Home conecta `NavigationSession.reroute` a `_routing.route` vehicular y
Navigation V2 usa umbrales operacionales fijos (p.ej. salida de ruta). No se
habilita navegación guiada para otros modos sin demostrar rerouting y maniobras
coherentes. El CTA para walking/cycling es «Ver ruta en el mapa», que reduce
el panel; no inicia GPS guiado ni rerouting vehicular.

## Horarios

Programar mantiene fecha/hora seleccionadas explícitas y aviso de planificación
sin predicciones. Una ruta ya calculada se muestra como referencia actual;
no se estima tráfico/servicio futuro. Con Programar, no se calcula una nueva ruta
como si fuera futura, ni se inicia navegación actual. Para consultar otro modo
con una referencia existente se pide volver a Ahora.

## Pruebas y validación

`test/services/mode_routing_service_test.dart` comprueba configuración de grafos,
propagación de modo, path/perfil, métricas, alternativas, geometría, steps,
modo no soportado sin request y causas tipadas (red, timeout, no route, respuesta
inválida, indisponibilidad). HTTP simulado, sin Supabase ni proveedor real.

`test/widgets/multimodal_mobility_test.dart` comprueba cuatro tarjetas y estados
a 320/390/768/1440, selección y tránsito no disponible. Una integración del panel
verifica los mismos endpoints al pasar vehículo→walking→cycling, ningún request
transit, navegación no habilitada, ausencia del resumen vehicular, error de modo
conservando la ruta anterior y retry. Programar conserva su aviso.

Se actualizó solo la expectativa de estados iniciales en
`map_experience_v2_test.dart`: tres proveedores configurados sin consultar y
transporte público sin fuente. Se conserva el resto de su cobertura vehicular.

Se intentó `dart format` con la lista explícita de archivos modificados. Quedó
sin salida aproximadamente 20 segundos y se interrumpió conforme a la instrucción
del bloque. No se repitió ni se iniciaron tests nuevos, regresiones, analyze o
suite. No se certifican formato, compilación, responsive ni tests verdes.
`git diff --check` pasó. Comandos de validación local:

```powershell
dart format lib/config/osrm_config.dart lib/services/osrm_routing_service.dart lib/services/mode_routing_service.dart lib/mobility/routing/routing_capabilities.dart lib/widgets/map_search_panel.dart lib/widgets/travel_mode_selector.dart lib/widgets/route_alternatives_selector.dart lib/widgets/departure_time_selector.dart test/services/mode_routing_service_test.dart test/widgets/multimodal_mobility_test.dart test/screens/home/map_experience_v2_test.dart
flutter test --no-pub test/services/mode_routing_service_test.dart test/widgets/multimodal_mobility_test.dart
flutter test --no-pub test/services/osrm_routing_service_test.dart test/widgets/travel_mode_selector_test.dart test/widgets/route_alternatives_selector_test.dart test/screens/home test/navigation test/mobility test/models/route_insight_test.dart test/widgets/mobility_recommendation_summary_test.dart test/screens/validation
flutter analyze --no-pub
flutter test --no-pub
git diff --check
git status --short
```

Los endpoints foot/bike se comprobaron con respuestas reales solo en el ejemplo
documentado. Eso no sustituye pruebas de UI y regresión ni valida cada trayecto.

## OE3 y objetivo general: afirmaciones permitidas

| Dimensión | Implementado | Parcial / limitación | No disponible |
|---|---|---|---|
| Rutas | Vehículo, caminar y bicicleta: proveedores reales y geometrías/medidas propias | Dependencia de cobertura y demo sin SLA; validación local pendiente | Routing transit |
| Medios | Elección explícita y estados observados por modo | Comparación descriptiva; recomendación de ruta solo vehicular | Ranking global de medios sin metodología |
| Horarios | Selección fecha/hora, contexto y referencia actual honesta | Planificación sin anticipar condiciones | Predicción futura o horarios de servicio transit |
| Navegación | Navigation V2 vehicular | Rutas no vehiculares visibles en mapa | Guía y rerouting a pie/bici |

El bloque reduce la brecha de medios y rutas de OE3 mediante consultas reales
por modo, pero no permite declarar cumplimiento completo de recomendación sobre
horarios ni elección automática global del mejor transporte. Tampoco agrega IA,
ML, tráfico real, datos sintéticos, nuevas analytics ni procesamiento Big Data.
