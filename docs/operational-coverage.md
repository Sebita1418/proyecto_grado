# Cobertura operativa: Bucaramanga, Girón y Floridablanca

Ampliación del 14 de octubre de 2026 sobre `feature/android-end-to-end-validation`,
base `226f1a4`. Se conservan los cambios previos de autenticación Google.

## Fuente y ámbito

Se mantiene el recurso inicial de Bucaramanga (68001) y se añaden Girón (68307)
y Floridablanca (68276) de la misma capa **Municipio (317), DANE MGN 2024**.
Los identificadores, nombres, año, tipo municipal, geometrías, CRS, consultas
exactas, bytes y SHA-256 están en [la procedencia cartográfica](../assets/geo/README.md).
Los archivos son GeoJSON WGS84 en longitud-latitud y se redistribuyen con
atribución DANE, CC BY 4.0. No se simplificaron ni disolvieron las geometrías.
No se incorpora Piedecuesta ni se afirma cobertura de todo el AMB.

El MGN es una referencia geoestadística de un productor oficial. No representa
una nueva certificación jurídica de deslinde ni precisión predial; la vigencia
incorporada es 2024.

## Servicio y fallo parcial

`MunicipalBoundaryService` admite una lista inmutable/configurable de
`MunicipalTerritory` y un cargador por municipio. La configuración productiva
incluye los tres recursos. La geometría se verifica contra el código, nombre,
tipo y año configurados antes de usar el motor `MunicipalGeometry`, que conserva
su algoritmo anterior de ray casting, huecos, multipolígonos y fronteras.

La pertenencia operativa es la unión lógica de los municipios: no se construye
otra geometría ni se pierde detalle de frontera. `polygons` expone los anillos
originales para el mapa. `CoverageAssessment` devuelve los municipios
verificados que contienen el punto, con código/nombre. En una frontera
compartida puede devolver ambos; el orden de configuración es determinista.

| Datos y punto | Estado | Uso como extremo |
| --- | --- | --- |
| Dentro de cualquier polígono verificado | Dentro, con municipio | Permitido |
| Fuera de todos, con los tres recursos cargados | Fuera de cobertura | Rechazado con mensaje |
| Sin coincidencia y al menos un recurso fallido/ausente | Desconocido | No autorizado; reintento disponible |
| Coordenadas inválidas | Desconocido, razón específica | No autorizado |

Una carga fallida de Girón no impide autorizar un punto verificado de
Bucaramanga/Floridablanca, pero tampoco permite llamar «fuera» a un punto sin
coincidencia. `available` indica que el conjunto está completo; `loadErrors`
identifica los recursos fallidos. El reintento conserva geometrías válidas y
solo recarga las pendientes. Las cargas concurrentes se comparten.

Se preservan los constructores con cargador único/GeoJSON sintético para las
pruebas anteriores. La configuración explícita de Bucaramanga sola sigue
disponible y cuenta con regresiones contra los mismos vecinos.

## Integración

- GPS de Girón/Floridablanca ahora puede servir como origen válido y no muestra
  el aviso de exterior por la antigua restricción a Bucaramanga.
- Photon/Nominatim mantienen los proveedores, debounce, caché y descarte de
  respuestas obsoletas. Una dirección sin ciudad consulta con el municipio del
  GPS **si fue identificado por el polígono**. Sin identificación se mantiene
  Bucaramanga como contexto de búsqueda; una ciudad explícita tiene prioridad.
  No se multiplica automáticamente la consulta por tres. Para direcciones en
  otro municipio, escribir su nombre. La cobertura postal de los proveedores
  sigue dependiendo de sus datos y no se garantiza numeración exacta.
- Los POI conservan su búsqueda. El texto de ciudad no autoriza las coordenadas:
  los resultados se clasifican por GIS incluso si el proveedor escribe otro nombre.
- Origen/destino, selección manual y OSRM reutilizan el mismo servicio. Se
  permiten Girón–Bucaramanga, Girón–Floridablanca y Floridablanca–Bucaramanga.
  No se validan todos los vértices de la ruta como extremos: atravesar temporalmente
  Piedecuesta u otra zona no invalida extremos autorizados.
- El seguimiento de navegación conserva su lógica y los avisos de GPS exterior
  usan el estado de la cobertura ampliada. No se alteró la recomendación de
  movilidad ni se incorporaron mediciones de tráfico.
- Los reportes no tenían una restricción municipal explícita. Se mantiene su
  autorización, publicación, Realtime y validación de coordenadas; no se añade
  otra regla territorial. Se probó publicación simulada con GPS de Girón.
- Se conservan componentes, colores y disposición Figma. Se actualizan los
  textos de cobertura y el título de mapa. El marcador inicial de Bucaramanga
  sigue identificado como esa ubicación concreta, no como límite operativo.

## Pruebas y evidencia

Las referencias existentes de Nominatim se conservan en
`test/fixtures/boundary-reference-points.json` con consulta, fecha, respuesta y
licencia. Las pruebas reales contrastan UIS/Parque Santander en Bucaramanga,
Girón y Floridablanca como interiores, y Piedecuesta como exterior. Esos puntos
proceden del proveedor; no fueron inventados ni se usan para construir límites.

Las nuevas suites `operational_coverage_test.dart`,
`operational_geocoding_test.dart` y `operational_coverage_flow_test.dart` prueban
configuración, fallos parciales, identidad inválida, recuperación, huecos,
islas/fronteras, municipio de GPS, búsquedas, extremos intermunicipales, inicio
de navegación con tramo externo, origen manual y reportes. Las operaciones
HTTP, GPS, métricas y publicación están simuladas para que sean deterministas;
no constituyen ensayos físicos de rutas ni evidencia de mejora de movilidad.

## Archivos

Nuevos: dos GeoJSON municipales, este informe, las tres suites y
`test/support/operational_coverage_fixtures.dart`.

Modificados: `municipal_boundary_service.dart`, `municipal_coverage.dart`,
contexto en `address_query.dart`/`geocoding_service.dart`/`place_suggestion_service.dart`,
textos de `map_search_panel.dart`/`rutas_screen.dart`, `pubspec.yaml` solo para
assets, README cartográfico, documentos geográficos/Android y expectativas de
las pruebas territoriales anteriores. El motor geométrico se conserva.

No se agregaron dependencias, no se modificó `pubspec.lock`, no se tocaron
credenciales ni stash y no se crearon commits/push/PR. Los archivos Dart y
manifiesto de la corrección Google se verifican por SHA-256 contra el inicio
de esta fase para demostrar su conservación.

## Android y alcance académico

Validación ejecutada en esta fase:

- `flutter analyze --no-pub`: `No issues found!` (4,3 s), `coverage-three-analyze.log`.
- `flutter test --no-pub`: `01:15 +721: All tests passed!`, `coverage-three-full-tests.log`.
- Son 19 pruebas nuevas sobre las 702 que ya incluían Google Android. Se
  mantienen también las regresiones de login, navegación, incidentes y Figma.
- `git diff --check`: comprobación final sin errores de whitespace.
- `dart format`: solo archivos Dart creados/modificados en la ampliación.
- `flutter build apk --debug --no-pub`: APK generado en 92,7 s, registro
  `coverage-three-android-build.log`; entrega en
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Se inspeccionó el ZIP del APK: incluye los tres GeoJSON con los mismos bytes
  y SHA-256 que los recursos originales, sin modificaciones al empaquetarlos.
- Las huellas de `pubspec.lock`, manifiesto OAuth, Login, configuración de
  redirect y sus pruebas coinciden con las registradas antes de la ampliación.

Flutter regeneró dos archivos de plugins Linux durante las verificaciones.
Como estaban limpios al comienzo, se retiró solamente ese diff incidental
mediante edición de archivos, sin `git restore`, reset o manipulación del stash.

La compilación APK permite entregar la funcionalidad actualizada. En esta
fase el S22 no aparece conectado; no se certifican interacciones físicas ni
se selecciona una cuenta Google. Probar en el teléfono GPS desde Girón,
destinos en Bucaramanga/Floridablanca, selección manual junto a fronteras,
rechazo de extremos en Piedecuesta, envío de reportes e inicio de navegación.
Los resultados reales de esos recorridos deben registrarse por separado.

**La ampliación es operativa. La propuesta académica y sus objetivos originales
no se modifican sin aprobación de la tutora.** No se presentan estas pruebas
funcionales como mediciones de reducción de tiempos, mejora de seguridad o
impacto de movilidad; esos resultados aún deben obtenerse mediante evaluación.
