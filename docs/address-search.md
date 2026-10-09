# Búsqueda de lugares y direcciones

Photon conserva el autocomplete con debounce de 450 ms y descarte por versión
de consulta. `AddressQuery` expande Cra/Cr/Kr, Cl, Av, Diag y Trans únicamente ante
numeración. Conserva la consulta original y separa vía principal, número
secundario y placa: «Cl 69 6-51» representa Calle 69, secundario 6, placa 51.
Reconoce «Calle 45 Carrera 27» y «Calle 45 con Carrera 27» como consultas de
intersección; no construye ni interpola coordenadas para ellas.

Una ciudad explícita tiene prioridad: no se añade Bucaramanga a la consulta.
Una dirección sin ciudad recibe «Bucaramanga, Santander, Colombia» solo en la
consulta al proveedor, conservando el texto original. Los POI mantienen su
búsqueda anterior con preferencia por ubicación. Las direcciones con contexto
municipal omiten lat/lon y viewbox: no se impone un rectángulo como límite.
No se deduce un municipio por cercanía. Resultados cuya ciudad informada
contradiga la solicitada se descartan; sin ciudad informada no se certifica
una coincidencia específica con ciudad explícita.

Origen manual y destino usan el mismo servicio. Seleccionar una sugerencia
guarda las coordenadas del proveedor y evita geocodificar nuevamente al
calcular. La etiqueta de Photon incluye número de inmueble cuando está presente.

En consultas de dirección, «Buscar dirección» permite consultar Nominatim si
las sugerencias Photon no sirven. Es una acción explícita, nunca una petición
por tecla. Presenta el resultado para seleccionarlo antes del cálculo. Editar
el campo o desmontar el panel invalida respuestas pendientes y detiene las
variantes siguientes. «Calcular ruta» con dirección sin seleccionar primero
muestra candidatos: el usuario selecciona uno y después calcula. Así, un
resultado de calle no se enruta silenciosamente como si fuera una puerta.
El flujo directo de POI se conserva. Los resultados vacíos no generan rutas.

## Consultas y ranking

Máximo **cuatro solicitudes secuenciales** por resolución explícita de una
dirección completa, con ciudad preservada en cada variante:

1. `Calle 69 # 6-51`.
2. `Calle 69 6-51`; con ciudad explícita se expresa como consulta estructurada
   `street=6-51 Calle 69`, `city=...`, `country=Colombia` (y estado si se escribió).
3. `Calle 69 6 51`.
4. `Calle 69` como último fallback aproximado.

Se detiene cuando existe evidencia específica; un error detiene la secuencia
y conserva candidatos anteriores si existen. Cada consulta de dirección pide
hasta cinco resultados con `addressdetails=1` y los ordena;
todos los candidatos válidos de las variantes se deduplican y vuelven a ordenar,
incluyendo múltiples coincidencias específicas para selección explícita. Photon sigue
haciendo una sola solicitud por consulta con debounce, sin fallback automático
a Nominatim. Las consultas estructuradas nunca combinan `q` con `street/city`.

Ranking lexicográfico determinista, sin pesos: compatibilidad de vía y placa,
ciudad escrita, distancia al bias cuando no hay ciudad explícita, completitud
de campos de dirección y orden del proveedor. Las partes numéricas se comparan
como tokens: `6-51` no equivale a `65-1`. No se modifica la duración OSRM.

## Precisión

«Coincidencia específica» exige vía y numeración compatibles en los campos
devueltos por el proveedor; también ciudad compatible cuando se escribió.
El municipio se lee de campos administrativos: en los datos actuales de
Nominatim, `city=Perímetro Urbano Bucaramanga` y `county=Bucaramanga` representan
el municipio solicitado. Solo se admite esa combinación si ambos nombres
concuerdan; no se infiere Bucaramanga para Floridablanca, Girón o Piedecuesta.
No basta con repetir el texto solicitado en una etiqueta. «Coincidencia
aproximada · numeración exacta no confirmada» identifica calles, intersecciones
no verificadas o datos incompletos/incompatibles. Los POI se identifican como
«Lugar». Se conservan las coordenadas reales y el aviso tras seleccionar.
No hay interpolación de puertas. «Elegir origen/destino en el mapa» reutiliza
el selector de puntos de reportes con etiquetas específicas. Solo confirma
coordenadas después de un toque o de elegir GPS y confirmar. Cancelar conserva
la selección. El punto manual no certifica una dirección postal. Home muestra
el marcador y centra el mapa inmediatamente al seleccionar, antes de calcular.
Editar el campo retira el marcador previo.

Nominatim tiene timeout de 8 s, caché de hasta 100 consultas por instancia y
una cola compartida en el proceso con al menos 1 s entre solicitudes. La clave
de caché incluye el bias para no reutilizar otra ubicación por error. Esta
cola **no coordina clientes diferentes**. El servidor público tiene un límite
de 1 solicitud/s para toda la aplicación y prohíbe autocomplete. Una entrega
con tráfico concurrente necesita un proxy con limitación global y caché o una
instancia/proveedor adecuado: https://operations.osmfoundation.org/policies/nominatim/.

La cobertura de OpenStreetMap determina si una puerta o intersección está
indexada. El proveedor puede devolver una calle en vez del inmueble exacto:
la UI muestra la etiqueta recibida, sin inventar numeración ni intersecciones.
Los tests no certifican la existencia actual de una dirección en los datos
públicos; HTTP, GPS y Realtime están controlados en las pruebas.

## Cobertura real y alternativas (9 de octubre de 2026)

Archivos de esta fase:

- `lib/services/address_query.dart`: clasificación, Kr, espacios en placa y contexto municipal.
- `lib/services/place_suggestion_service.dart`: contexto de direcciones y lectura administrativa de Photon.
- `lib/services/geocoding_service.dart`: candidatos múltiples, caché de listas y errores de timeout.
- `lib/widgets/map_search_panel.dart`: selección manual y notificación de puntos seleccionados/editados.
- `lib/widgets/report_location_picker.dart`: etiquetas configurables; los reportes conservan sus valores por defecto.
- `lib/screens/home/home_screen.dart`: marcadores y cámara de origen/destino antes del cálculo.
- `test/services/address_search_test.dart` y `colombia_address_resolution_test.dart`: expectativas de contexto actualizadas.
- `test/screens/home/address_flow_test.dart`: mock adaptado al contrato de candidatos múltiples.
- Nuevos `test/services/bucaramanga_address_test.dart` y `test/screens/home/address_map_selection_test.dart`.
- Este documento.

Validación final ejecutada en esta fase:

- `flutter analyze --no-pub`: `No issues found!` (3,4 s), evidencia en `address-analyze.log`.
- `flutter test --no-pub`: `00:58 +653: All tests passed!`, evidencia en `address-full-tests.log`.
- `git diff --check`: código 0. Git solo avisa de conversión futura LF/CRLF del panel.
- `dart format`: limitado a los archivos Dart modificados o creados.

La suite incluye formatos, clasificación, candidatos ambiguos, municipio,
vacíos, HTTP/JSON/red, timeout, respuestas obsoletas, origen/destino, marcadores,
selección manual y coordenadas entregadas al servicio OSRM simulado. Los tests
de navegación, GPS, reportes y fidelidad visual existentes también pasaron.
Las consultas reales son separadas de las pruebas deterministas.

Estado final: rama `feature/bucaramanga-address-geocoding`, base `6b4e134`,
diez archivos versionados modificados y dos pruebas nuevas. Sin cambios en
`pubspec.lock`, dependencias o referencias Figma; `stash@{0}` se conserva.
No se crearon commits, push ni PR. Los riesgos restantes son cobertura OSM,
disponibilidad/cuotas de servidores públicos y ausencia de límite municipal
oficial; no se promete precisión de puerta ni intersección no verificada.

Tres consultas explícitas a Nominatim, espaciadas más de un segundo, dieron
HTTP 200. Son observaciones de cobertura, no validaciones de domicilio:

| Consulta en Bucaramanga, Santander, Colombia | Resultado del proveedor | Clasificación |
| --- | --- | --- |
| Carrera 27 # 45-30 | Cinco tramos de Carrera 27, sin `house_number`; primer punto 7.1383641, -73.1202986 | Aproximado y ambiguo; placa no confirmada |
| Calle 36 # 15-20 | Cinco tramos de Calle 36, sin `house_number`; primer punto 7.1241595, -73.1115596 | Aproximado y ambiguo; placa no confirmada |
| Calle 45 con Carrera 27 | Lista vacía | Sin cobertura de esta consulta |

Estas coordenadas proceden del proveedor y se registran solo como evidencia;
no son resultados fijos ni se incorporan al código. No demuestran que los
primeros tramos sean cercanos a las placas solicitadas. El usuario puede
seleccionar una aproximación con su aviso o elegir el punto en el mapa.

Se mantienen Photon para autocomplete y Nominatim para resolución explícita,
sin dependencias, credenciales ni cambios de facturación. Una instancia propia
de estos proveedores permite controlar disponibilidad y límites, pero no añade
las placas que falten en OSM. [Política de Nominatim](https://operations.osmfoundation.org/policies/nominatim/)
y [API de Photon](https://github.com/komoot/photon/blob/master/docs/api-v1.md).

[Mapbox Geocoding](https://docs.mapbox.com/api/search/geocoding/) ofrece campos
de exactitud y coincidencia de dirección, pero requiere token y revisión de
condiciones de almacenamiento y costos. [Google Geocoding](https://developers.google.com/maps/documentation/geocoding/usage-and-billing)
requiere credenciales y facturación; también exige revisar sus condiciones para
mostrar resultados en el mapa existente. No se han ensayado estos servicios
con las direcciones locales, por lo que no se afirma mejor cobertura. Cambiar
a ellos queda pendiente de autorización y de una comparación con muestra real.

No existe en el repositorio un polígono municipal verificable. El filtro de
campos administrativos reduce coincidencias contradictorias, pero no certifica
pertenencia municipal cuando falta esa información ni limita los puntos
manuales. Incorporar un polígono oficial con fuente, licencia y fecha y aplicar
validación punto-en-polígono queda como siguiente tarea.

## Prueba manual de Sebastián

1. Iniciar sesión, habilitar GPS y escribir «Calle 69 # 6-51».
2. Revisar las sugerencias; si no corresponden, pulsar «Buscar dirección».
   Seleccionar el resultado cuya etiqueta corresponda. Si no existe, verificar
   «Calle 69» y registrar la falta de cobertura del inmueble, sin asumir
   que el centro de una calle sea la puerta solicitada.
3. Calcular, comparar alternativas/recomendación, elegir e iniciar ruta.
4. Comprobar vía, icono, distancia y avance de maniobras con GPS real.
5. En otro cliente autenticado publicar un reporte y comprobar que aparece
   durante navegación, tanto en el mapa como en «Reportes de la vía».
6. Arrastrar mapa, volver a seguir ubicación y comprobar continuidad.
7. En un recorrido seguro, registrar tres fixes fuera de ruta (>60 m):
   comprobar «Recalculando ruta…», nueva geometría y maniobras sin reiniciar.
   Repetir sin conexión: la ruta anterior debe conservarse.
8. Llegar (40 m), finalizar y volver a planificación. Probar además
   «Calle 69 # 6-51, Floridablanca», «Carrera 27 # 36-14, Bucaramanga»,
   «Cra 27 36-14, Bucaramanga», «Calle 45 con Carrera 27, Bucaramanga»,
   «UIS» y «Cacique», también en origen manual. Revisar el aviso de precisión
   antes de seleccionar; no asumir que el proveedor tiene todas las placas.

La integración remota se hizo por parches complementarios: panel plegable,
lista de reportes, edición/descarte de borradores, controles y presentación.
Home, estado de navegación y tests V2 locales se conservaron. Los reportes
continúan separados de OSRM: no alteran rutas ni simulan tráfico.
