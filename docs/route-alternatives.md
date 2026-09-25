# B4 / B7 — Selección y comparación objetiva de alternativas vehiculares

Clasificación: Derivado funcional / UX apoyado en infraestructura existente.
Baseline B4: `97c9a48b2cbff289ba047865d74af894a8de3773`.
Relación provisional con OE3/OE4; pendiente de contraste con FDC-124.

## Flujo integrado

`MapSearchPanel` conserva la resolución actual de origen/destino (GPS, selección
Photon o fallback Nominatim) y llama una vez a
`OsrmRoutingService.routeAlternatives`. El servicio incorporado en #26 ya solicita
`alternatives=true`; B4 no modifica servicios ni contratos del dominio.

El panel conserva todas las candidatas como `List<RouteResult>` no modificable,
en orden del proveedor, y un índice seleccionado. La primera es únicamente la
selección inicial. `onRouteChanged` comunica el resultado seleccionado a Home.
Home y RouteMap conservan su contrato y dibujan una geometría a la vez.

Cambiar de alternativa solo actualiza estado local y el callback: no vuelve a
consultar OSRM, Photon o Nominatim. La tarjeta, sus detalles y la geometría usan
la misma ruta seleccionada; las etiquetas de origen y destino se conservan.

## Presentación

La tarjeta usa el título neutral «Ruta seleccionada». Un control compacto indica
«Alternativa N de M seleccionada» y abre una hoja desplazable con todas las rutas.
Cada opción muestra su número, distancia y duración estimada. La selección se
identifica con icono, texto «Seleccionada» y semántica de selección, además del
color. La lista se construye bajo demanda y no aumenta la altura del panel del
mapa en función de la cantidad de rutas.

## B7: comparación objetiva

Baseline B7: `develop@9c704fa3f0309fcaddd97c5c9784d9081ceda4b4`, que incluye B6.
PR #27 (`feature/demo-presentation-polish`) seguía OPEN al consultar GitHub CLI;
sus nueve archivos y su rama no se modifican. La integración se limita al selector
que ya recibe las rutas reales de `routeAlternatives()`. No requiere cambios en
Home, MapSearchPanel, RouteResultCard ni RouteMap.

`RouteAlternativesAnalysisService` es puro: recibe los `RouteResult` existentes y
produce índices de mínimos y diferencias inmutables en el orden original. No copia
modelos de ruta, no altera geometrías o métricas y no realiza HTTP. Las unidades
fuente son `distanceMeters` (metros) y `durationSeconds` (segundos), validadas por
OSRM. El análisis también rechaza métricas negativas o no finitas con ArgumentError;
no reemplaza datos inválidos por ceros. Una lista vacía tiene índices nulos y no
produce controles. Una sola ruta tiene diferencias cero, pero la UI omite etiquetas
comparativas y controles de cambio.

“Más rápida” y “Más corta” son comparaciones determinísticas de las alternativas
devueltas por el proveedor. NO constituyen una recomendación personalizada.
Cada mínimo se calcula independientemente; una ruta puede recibir ambas etiquetas.
En empates exactos gana la primera alternativa según orden del proveedor, sin usar
la otra métrica para desempatar. Los mínimos se calculan antes del redondeo visual.
Las otras rutas empatadas tienen diferencia cero, que no se muestra.

La hoja muestra diferencias positivas de duración frente a la más rápida y de
distancia frente a la más corta. Una leyenda común indica explícitamente las
referencias y cada opción muestra, por ejemplo, `+4 min` o `+1.2 km`. Duración
usa minutos y horas; distancia diferencial usa metros por debajo de 1 km y km con
un decimal a partir de ahí. Diferencias menores de un minuto o de un metro se
muestran como `<1 min` o `<1 m`, evitando `+0` y falsa precisión. Se mantiene el
punto decimal de la UI existente. No hay un formatter compartido en el baseline:
los getters de formato de la tarjeta están ligados al widget de PR #27. El selector
centraliza su formato de duración para valores y diferencias, siguiendo la misma
convención de minutos/horas sin tocar esa tarjeta.

La selección sigue siendo manual, inicialmente en la primera ruta del proveedor.
La integración conserva Diseño A: control compacto sobre el mapa y hoja modal
Material 3 con tipografía, colores y controles del tema existente; no añade
acciones de recomendación ni modifica el panel o la tarjeta de resultado.
Cambiarla no consulta nuevamente OSRM y mantiene tarjeta, detalles y mapa usando
la misma candidata. La hoja usa el 90 % de la altura disponible al abrirse, con viewport
estable y scroll para evitar saltos por el tamaño variable de las opciones.
Conserva la semántica de selección; etiquetas
y diferencias son texto accesible, además del icono y texto de selección. La altura
del control sobre el mapa no crece con el número de alternativas.

Si OSRM devuelve una sola ruta, se presenta normalmente y se indica «Se recibió
una sola ruta vehicular», sin un selector ficticio. Cerrar la hoja sin elegir no
cambia el resultado. Las métricas y acciones de la tarjeta pueden pasar a otra
línea para admitir pantallas estrechas y texto ampliado.

## Invalidación y concurrencia

Una edición real de origen/destino, cambio entre origen manual/GPS o cambio de
coordenadas GPS limpia candidatas y selección. Cursor, selección de texto y
composición sin cambio del texto no invalidan resultados. Al recalcular se limpia
el resultado anterior antes de consultar; un error no deja rutas anteriores
presentadas como vigentes y permite reintentar.

Se conserva el identificador de cálculo y las comprobaciones `mounted` para
descartar respuestas obsoletas y posteriores al desmontaje. Un selector abierto
se cierra al desaparecer su resultado, por ejemplo ante un cambio de GPS; una
selección asociada a otro cálculo tampoco puede modificar el actual.

## Límites

- Solo rutas vehiculares devueltas por el proveedor; no se garantiza una cantidad
  mínima de alternativas ni disponibilidad del servidor.
- No hay ranking, scoring, optimización ni recomendaciones personalizadas.
- No se integra B6 ni se crean `MobilityRecommendation` o un motor concreto.
- No se persisten rutas ni hay tráfico observado, ahorro, horarios o multimodalidad.
- B7 compara métricas objetivas; la elección es manual. La duración es estimada y el orden
  del proveedor no se presenta como una evaluación personalizada.
- OE3 recibe un avance parcial de consulta de candidatas; OE4 recibe la interfaz
  para elegirlas. No se acredita cumplimiento institucional ni FDC EXPLÍCITO.
- Las preferencias B6 permanecen independientes. No hay IA, ranking por preferencias,
  tráfico en tiempo real, reportes ciudadanos ni disponibilidad o ahorro inventados.
- Los mínimos se refieren solo a las rutas recibidas, no a todas las rutas posibles.
  FDC-124 continúa pendiente de contraste; B7 no reescribe la matriz B5.

## Verificación local de B4

Las pruebas usan respuestas controladas identificadas como datos de prueba;
no acreditan disponibilidad de alternativas para un viaje real.

- Flujo Home: selección inicial/cambio, geometría, métricas, detalles, número de
  consultas, una ruta, recálculo, errores, invalidación, GPS, obsolescencia y dispose.
- Selector: lista desplazable de 12 candidatas, semántica, cancelación y una ruta.
- Home, selector y tarjeta: 320, 390, 768 y 1440 px con texto al 150 %.
- Regresiones existentes de Photon, fallback, cursor, detalles y modificación.

Validación final con Flutter 3.47.2:

- Selector: 6 pruebas aprobadas; la selección semántica se verifica con
  `flagsCollection.isSelected == Tristate.isTrue`, sin API deprecada.
- RouteResultCard: 4 pruebas aprobadas.
- Flujo Home: 17 pruebas aprobadas.
- Suite completa de 25 archivos de tests versionados y nuevos de B4:
  148 pruebas aprobadas, sin fallos.
- `flutter analyze` sobre los 69 archivos Dart de la entrega: sin problemas.
- `flutter build web --no-pub`: correcto; Wasm dry run completado.
- `git diff --check`: sin errores.

Los avisos de flutter_map sobre tiles públicos OSM no son fallos de pruebas.
La infraestructura OSM/OSRM para producción requiere una decisión posterior;
no se cambia como parte de B4.

El archivo histórico no rastreado `test/widgets/route_summary_card_test.dart`
queda fuera de la entrega y de las validaciones; permanece intacto.

## Verificación local de B7

- 10 pruebas del análisis puro: vacío, única ruta, mínimos independientes y
  coincidentes, empates de ambas métricas, estabilidad, diferencias exactas,
  inmutabilidad, conservación de rutas y rechazo de métricas inválidas.
- 11 pruebas del selector: conserva las seis anteriores y añade etiquetas,
  diferencias, semántica de etiquetas, empates, unidades/horas, valores pequeños,
  ausencia de candidatas y selección sobre respuesta OSRM con una sola consulta HTTP.
- 17 pruebas existentes del flujo Home aprobadas, sin modificar sus archivos:
  mapa, métricas y detalles sincronizados; selección manual sin nuevas consultas;
  invalidación, errores y concurrencia. Total específico: 38 aprobadas.
- Responsive: selector y flujo integrado en 320, 390, 768 y 1440 px con texto
  al 150 %, sin overflow. Scroll permite alcanzar la alternativa 12; selección
  identificable por icono, texto y `flagsCollection.isSelected`.
- `flutter analyze`: cinco errores exclusivamente del archivo histórico no
  rastreado `test/widgets/route_summary_card_test.dart`.
- `flutter test`: 180 pruebas aprobadas y un único fallo de compilación de ese
  archivo histórico, que referencia un widget inexistente.
- Análisis equivalente (`dart analyze`, lista de `git ls-files '*.dart'` más
  los dos Dart nuevos B7): 73 archivos, sin problemas.
- Suite equivalente (`flutter test`, lista de los tests versionados más el
  nuevo test B7): 27 archivos, 180 pruebas aprobadas.
- `flutter build web --no-pub`: aprobado; salida en `build/web`, incluido
  el dry run de Wasm.
- `git diff --check`: aprobado. Formato aplicado únicamente a los cuatro
  archivos Dart B7; los archivos generados previamente marcados como modificados
  se conservan fuera de la entrega.

No se modifican exclusiones globales, archivos del PR #27, `lib/mobility/**`,
preferencias B6 ni dependencias. El test histórico sigue intacto, no rastreado y
fuera del staging; SHA-256:
`612D4C979AF5361E330296EAA4EE98C68EE0B4D5C34802E9FCE4FDEB2FEF8086`.
Las pruebas usan datos controlados; no certifican disponibilidad del proveedor,
precisión de tiempos en un viaje real, uso con lector de pantalla real ni
funcionamiento nativo. La duración OSRM es estimada, no tráfico observado.
