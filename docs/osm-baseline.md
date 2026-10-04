# Baseline OSM en consolidación

Base: develop cc0dfc5. Referencias adaptadas: ecec4cf y 4c1bce2.

> Registro histórico de esa integración. «Flujo activo», pendientes y pruebas
> de abajo describen cc0dfc5, no el estado actual. En `f2009b2`, Home ya consulta
> alternativas OSRM y permite selección manual; RutasScreen conserva el cálculo
> pendiente. El dominio neutral y la UI local de preferencias también existen.
> Consultar [trazabilidad B5](requirements/traceability_matrix.md),
> [alternativas](route-alternatives.md) y [preferencias](mobility-preferences.md).

## Flujo activo

- Supabase OAuth de Google y creación del perfil al iniciar sesión. Home,
  navegación por rol, pantalla Perfil y pruebas del PR #17 se conservan.
- Photon: sugerencias desde tres caracteres, debounce de 450 ms, máximo cinco,
  bias Bucaramanga y control independiente de respuestas obsoletas por campo.
- Nominatim: búsqueda explícita al pulsar Calcular ruta para texto sin una
  ubicación seleccionada. No se utiliza para autocomplete.
- Flutter Map/OSM: marcadores, atribución, autoencuadre, callback de tap y
  reinicio. El listado y búsqueda de rutas de Supabase permanecen.
- No se consulta un motor de routing. No hay geometría, distancia ni duración
  simuladas. La pantalla indica que el cálculo vehicular está pendiente.

La selección por tap y el reinicio del PR #16 se adaptan a latlong2. Las
sugerencias y búsquedas manuales usan el mismo estado de coordenadas. Mover el
cursor no invalida una selección; editar el texto sí lo hace. Se conserva el
formulario existente, ampliado con espacios para sugerencias. Los PR #8–#10
no se incorporan.

## Legado conservado deliberadamente

| Componente | Uso actual | Decisión |
| --- | --- | --- |
| RoutePlannerController | Solo legado y tests | Desconectado de RutasScreen; reemplazo futuro |
| GoogleRouteResult | Modelo del controlador/servicio legado y tests | Conservar sin introducirlo en el nuevo dominio |
| GoogleRoutesService / GoogleRoutesConfig | Fábrica del controlador legado y tests | Sin llamadas desde el flujo activo |
| PolylineDecoder | Utilidad Google y tests | Sin consumidores en pantallas; revisión futura |
| RouteMarkers / RoutePolyline | Utilidades Google y tests | Sin consumidores en pantallas; revisión futura |
| google_maps_flutter | Importado por las tres utilidades anteriores y dos archivos de tests | Dependencia temporal necesaria para compilar ese legado |

La prueba de carga pendiente del PR #15 se conserva sin cambios, junto con el
resto de pruebas de controlador, modelo, servicio y utilidades Google. No se
elimina código para conseguir una suite verde. Retirar el SDK requiere decidir
en otro incremento la migración o retirada de esas utilidades y pruebas.
Google OAuth es independiente de esta decisión y permanece activo.

## Resolución de dependencias

Se conserva el lock de develop y se resuelve con flutter_map 8.3.2 y latlong2
0.10.1. No se copia el override objective_c 9.5.0 de la demo: la resolución
actual usa 9.6.0 y la suite recuperada pasó sin override en Windows con Flutter
3.47.2 / Dart 3.13.2. Esto no sustituye una compilación nativa Apple.

## Validación automática

- dart format aplicado a los 13 archivos Dart modificados o creados.
- flutter pub get: correcto, sin dependency_overrides.
- flutter analyze: No issues found.
- flutter test: 67 pruebas aprobadas, incluidos Perfil, loading del PR #15,
  servicios con MockClient, cámara OSM y ciclo de vida de RutasScreen.
- flutter build web --no-pub: correcto (build/web); dry run Wasm correcto.
- git diff --check: sin errores; Git informa avisos de conversión LF/CRLF.
- web/index.html: sin scripts ni patrones de claves Google Maps.
- Imports google_maps_flutter: tres utilidades y dos archivos de tests,
  todos de legado. Ninguno en pantallas o widgets.

## Trabajo posterior y revisión manual

- Definir el dominio y RoutingProvider futuro sin dependencia del proveedor;
  implementar OSRM en otro incremento. Si se solicita GeoJSON, el decoder de
  encoded polyline no es necesario.
- Revisar el legado antes de retirarlo y corregir sus textos con problemas de
  codificación si continúa conservándose.
- Validar OAuth real, redirect, políticas de perfiles de Supabase, usuario
  nuevo/existente/inactivo y acceso a Perfil/Administración según rol.
- Validar mapa, atribución, teclado, selección, errores y autoencuadre en web
  y plataformas objetivo. Las pruebas de servicios usan clientes simulados.
- Las pruebas automáticas no verifican disponibilidad, cuotas ni configuración
  de los servicios externos. Este incremento requiere revisión y prueba manual.
