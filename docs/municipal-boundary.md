# Cobertura territorial de Bucaramanga

La validación se centraliza en `MunicipalBoundaryService`, con un recurso local
versionado del DANE MGN 2024, municipio 68001. La fuente, consulta exacta, CRS,
licencia, fecha, número de vértices y SHA-256 están en
[`assets/geo/README.md`](../assets/geo/README.md). No se emplea un rectángulo,
centroide, cercanía o nombre textual para autorizar una coordenada.

## Motor GIS y política

`MunicipalGeometry` acepta Polygon, MultiPolygon, Feature y FeatureCollection.
Aplica ray casting con comprobación de punto sobre segmento, conserva los
anillos interiores y no depende de su orientación. Fronteras exteriores y
bordes de huecos se consideran dentro; el interior de un hueco queda fuera.
La tolerancia numérica es 1e-10 grados, no un buffer de cobertura ni una
estimación de error GPS. No se soportan polígonos que crucen el antimeridiano.

Se verifican coordenadas finitas/rangos WGS84, cierre, vértices distintos,
área no nula, cruces propios y huecos con vértices fuera del anillo exterior.
Esto no sustituye una herramienta GIS completa de reparación topológica.
El cargador de producción verifica además la identidad y vigencia municipal;
no acepta cualquier polígono como Bucaramanga. Fallos de lectura/JSON/geometría
se capturan sin cerrar la aplicación. La carga concurrente se comparte y los
fallos solo se reintentan por una acción explícita.

| Estado | Búsqueda y mapa | Selección y planificación |
| --- | --- | --- |
| Dentro | Resultado conservado y etiquetado | Se permite utilizar el extremo |
| Fuera | Resultado real conservado, etiqueta «Fuera de Bucaramanga» | Se explica qué extremo falla; no se calcula ni inicia ruta |
| Desconocido | Mapa y resultados disponibles, sin certificar cobertura | Se bloquea el uso para rutas hasta recuperar el recurso; botón de reintento |

Las coordenadas inválidas tienen una razón específica y nunca se presentan
como dentro ni como fuera. Una ciudad textual no puede anular el resultado
del algoritmo territorial.

## Integración

- Photon y Nominatim anotan cobertura de las coordenadas reales. Los candidatos
  exteriores no se convierten en coordenadas interiores ni en resultados vacíos.
  La caché de Nominatim reevalúa cobertura al recuperar el límite sin repetir HTTP.
- El planificador valida al seleccionar, antes del cálculo y antes de ofrecer
  inicio de navegación. Home vuelve a comprobar los extremos al iniciar.
- OSRM valida origen/destino antes de HTTP, también en recálculos. **No se
  valida cada punto del trazado**: un tramo externo no invalida extremos dentro.
  Ante fallo de recálculo se conserva la política previa de mantener la ruta.
- GPS exterior muestra un aviso dentro del panel y conserva la opción Cambiar
  para indicar otro origen. Durante navegación muestra un aviso informativo en
  la tarjeta existente, sin finalizar la ruta. No se deshabilita el GPS ni el
  movimiento del mapa.
- El selector manual muestra cualquier punto y permite moverlo. Confirmar se
  habilita solo con un punto permitido. Reportes conservan su selección anterior;
  la restricción de extremos se aplica al selector usado para planificación.
- La pantalla Rutas reutiliza la misma validación para sugerencias y taps.
  Un punto exterior no borra la selección previa. El límite se dibuja como
  contorno con colores del tema en Home, Rutas y el selector del planificador.
  No participa en autoencuadre ni recorta las rutas. Se incluye atribución DANE.

## Evidencia geográfica

El 9 de octubre de 2026 se consultaron cinco referencias reales a Nominatim,
espaciadas más de un segundo y con User-Agent de la aplicación. Las respuestas
originales, URL, fecha y licencia están en
[`test/fixtures/boundary-reference-points.json`](../test/fixtures/boundary-reference-points.json).
Son puntos OSM de referencia, no mediciones físicas ni límites OSM.

| Referencia | Latitud, longitud del proveedor | Resultado MGN 2024 |
| --- | --- | --- |
| Universidad Industrial de Santander | 7.1409311, -73.1198652 | Dentro |
| Parque Santander | 7.1196763, -73.1228536 | Dentro |
| Floridablanca | 7.0625677, -73.0859086 | Fuera |
| Girón | 7.0690690, -73.1700282 | Fuera |
| Piedecuesta | 6.9874808, -73.0504129 | Fuera |

Referencias de puntos: © OpenStreetMap contributors, [ODbL 1.0](https://www.openstreetmap.org/copyright).
Las coordenadas no se usan como resultados fijos de búsqueda ni para construir
el polígono. Los tests de referencia cargan una instancia del servicio con el
asset real, independiente del recurso sintético de las pruebas anteriores.

## Archivos y pruebas

Nuevos: `lib/models/municipal_coverage.dart`,
`lib/services/municipal_boundary_service.dart`, GeoJSON/README en `assets/geo`,
este documento, fixtures de referencia, `test/flutter_test_config.dart`,
`test/support/boundary_fixtures.dart` y seis suites nuevas:
`municipal_boundary_service_test.dart`, `municipal_boundary_real_test.dart`,
`territorial_geocoding_test.dart`, `territorial_routing_test.dart` y
`territorial_planner_test.dart` y `territorial_rutas_test.dart`.

Modificados: contratos `place_suggestion.dart`/`geocoding_result.dart`, servicios
Photon/Nominatim/OSRM, Home/Rutas, panel del planificador, mapa y selector de
puntos, tarjeta de navegación y `pubspec.yaml` únicamente para registrar el asset. No se añadieron
dependencias ni se modificó `pubspec.lock`.

Los tests antiguos usan un polígono sintético permisivo declarado en la
configuración de pruebas: sus coordenadas arbitrarias siguen comprobando UI,
red y navegación. Las pruebas territoriales inyectan polígonos propios o cargan
el asset real; no se afirma que ese rectángulo represente un municipio. Las
pruebas nuevas cubren huecos, frontera/próximos a frontera, islas, errores,
concurrencia, reintentos, caché, proveedores, GPS, selección manual, extremos
no permitidos y tramos externos. Todas las pruebas automatizadas son sin red.

## Verificación física en Android

Validación final ejecutada el 9 de octubre de 2026:

- `flutter analyze --no-pub`: `No issues found!` (3,3 s), registro en `boundary-analyze.log`.
- `flutter test --no-pub`: `01:01 +689: All tests passed!`, registro en `boundary-full-tests.log`.
- `git diff --check`: código 0, sin salida de errores.
- `dart format`: aplicado solo a archivos Dart creados/modificados.

Se añaden 36 pruebas a las 653 de la base. Los tests existentes de navegación,
incidentes, GPS, diseño responsive y búsqueda también pasaron. No se ejecutó
una prueba física en Android en esta sesión.

Git final: `feature/bucaramanga-municipal-boundary`, base `f06e9f4`, 13 archivos
modificados y 14 nuevos, sin commits/push/PR. `pubspec.lock` no presenta diff y
`stash@{0}` permanece como respaldo reservado. No se alteraron credenciales,
dependencias ni recursos de referencia Figma.

1. Probar GPS y planificación en UIS o Parque Santander; revisar el aviso y
   el contorno y calcular con otro extremo interior.
2. Probar GPS en Floridablanca/Girón/Piedecuesta: debe informar fuera y permitir
   Cambiar a un origen manual dentro. No debe llamar a OSRM con ese GPS exterior.
3. Seleccionar puntos a ambos lados del límite: el marcador se mueve libremente,
   pero Confirmar solo admite el interior/frontera. Revisar la precisión GPS
   cerca de bordes sin atribuirle precisión jurídica al MGN.
4. Verificar que una ruta de extremos interiores siga visible y pueda iniciarse
   aunque el proveedor la haga pasar fuera. Comprobar también incidentes y GPS.
5. En modo avión, verificar que el contorno/localización territorial siguen
   disponibles desde el asset; la búsqueda y OSRM conservan sus errores de red.

Pendientes: validar en dispositivo físico, mantener/actualizar la vigencia
cartográfica y contrastar diferencias próximas a frontera con cartografía de
deslinde autorizada. No se incorpora tolerancia basada en precisión GPS. El mapa y el geocodificador
conservan sus límites de disponibilidad/cuotas externos.
