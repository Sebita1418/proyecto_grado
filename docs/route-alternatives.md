# B4 — Consulta y selección de alternativas de ruta vehicular

Clasificación: Derivado funcional / UX apoyado en infraestructura existente.
Baseline: `97c9a48b2cbff289ba047865d74af894a8de3773`.
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
- No se integra B3 ni se crean `MobilityRecommendation` o un motor concreto.
- No hay persistencia, tráfico observado, ahorro, horarios ni multimodalidad.
- La comparación y elección son manuales. La duración es estimada y el orden
  del proveedor no se presenta como una evaluación personalizada.
- OE3 recibe un avance parcial de consulta de candidatas; OE4 recibe la interfaz
  para elegirlas. No se acredita cumplimiento institucional ni FDC EXPLÍCITO.

## Verificación local

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
