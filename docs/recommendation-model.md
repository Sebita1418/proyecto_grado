# Recomendación vehicular explicable

Baseline: `70e7987136d31c277045de3ceef281bf67a0ed9d`.
Rama: `feature/explainable-vehicle-recommendation`.

## Alcance y autoridad

`VehicleRecommendationEngine` implementa `MobilityRecommendationEngine` para
opciones vehiculares reales. Es una regla técnica provisional y reproducible,
no un requisito institucional ni una preferencia de tiempo/distancia del usuario.
FDC-124 sigue pendiente de contraste. Este incremento no acredita el cumplimiento
completo de RF-MOB-01 u OE3: no incorpora horarios ni comparación multimodal.
No es IA, no demuestra optimalidad global ni utiliza tráfico observado.

## Entradas, decisión y salida

Entradas: `MobilityContext` y `List<RouteOption>`. Cada candidata de OSRM se adapta
con `RouteOption.fromRouteResult`, `mode: driving`, `source: osrm` e identidad por
índice dentro del cálculo. Se reutiliza `RouteResult`; no hay otro modelo de ruta.
El adaptador existente conserva una copia inmutable y validada de la geometría.

El motor valida contexto, identidades únicas y datos de las opciones en su frontera,
incluso si un consumidor evita la fábrica del modelo. Rechaza geometrías inválidas,
coordenadas inválidas y métricas negativas/no finitas. No reemplaza datos por cero.
El motor rechaza candidatas cuyos extremos no coincidan con el contexto; MapSearchPanel las obtiene
de una única respuesta OSRM para los extremos del contexto.

Solo son elegibles las opciones `driving` incluidas en `context.allowedModes`.
La regla compara unidades originales sin redondear:

1. Menor `durationSeconds`.
2. Ante igualdad exacta, menor `distanceMeters`.
3. Ante igualdad de ambas métricas, primera opción en el orden del proveedor.

La misma entrada y orden producen la misma opción y razones. No se asignan pesos
ni puntuaciones inventadas y no se ordena la lista original. El recorrido de las
candidatas es lineal; la validación recorre también sus puntos de geometría.

Salida: `MobilityRecommendation`, con opción sugerida, todas las demás opciones
elegibles en orden original, razones estructuradas y fecha de evaluación.
`requestedAt` registra el inicio del cálculo; `evaluatedAt` usa el reloj real al
evaluar (inyectable para pruebas). La fecha no interviene en la elección.

Las razones distinguen mínimo único/compartido de duración, distancia cuando
realmente resuelve un empate y orden del proveedor cuando permanece un empate
completo. Una única candidata elegible se explica como tal, sin comparación.
Una lista vacía o sin candidatas elegibles produce
`NoEligibleVehicleRouteException`: no existe una recomendación ficticia.

`MobilityConditions` no interviene en esta política, ni siquiera si se entrega
algún campo conocido. Los valores desconocidos permanecen `null`; no representan
ausencia de congestión, incidentes o retrasos. No se emiten razones de condiciones.

## Preferencias: elegibilidad, no nuevos criterios

Se reutiliza `MobilityPreferencesService` sin modificarlo y se recarga por cada
cálculo, después de recibir OSRM y antes de seleccionar una ruta. No se escribe
almacenamiento desde el panel. Una selección manual no relee ni recalcula.

| Resultado de carga | Comportamiento |
| --- | --- |
| Conjunto vacío | Flujo vehicular por defecto: se permite driving sin atribuir esa elección al usuario. El resumen lo comunica. |
| Conjunto que incluye driving | Se evalúan las candidatas vehiculares. Otros modos guardados no se simulan. |
| Conjunto no vacío sin driving | No se selecciona ni dibuja una ruta; mensaje persistente de incompatibilidad. Se conservan puntos/textos para revisar preferencias desde Perfil y recalcular. |
| Fallo de lectura | No se asume conjunto vacío. Se muestra error y se permite reintentar con Calcular ruta. |

La API existente devuelve vacío tanto para almacenamiento ausente como para datos
obsoletos sin modos reconocidos. Este consumidor no puede distinguir esos casos;
el mensaje dice «Sin modos guardados», sin afirmar consentimiento para conducir.
La carga tiene el timeout de ocho segundos del servicio existente.

Las preferencias siguen siendo locales a la instalación/navegador y compartidas
entre cuentas; no se modifica esa semántica ni se incorpora persistencia Supabase.
El snapshot se aplica al cálculo actual; editar preferencias requiere recalcular.
OSRM puede haberse consultado antes de detectar incompatibilidad, pero sus rutas
no se muestran como compatibles ni se activa conducción silenciosamente.

## Integración productiva y selección manual

Home → MapSearchPanel → origen/destino → OSRM `routeAlternatives()` → preferencias
locales → `RouteOption`/`MobilityContext` → motor → `MobilityRecommendation` → índice
inicial → callback existente → mapa, tarjeta y detalles.

El panel mantiene las candidatas originales en orden OSRM. La identidad de la
opción sugerida permite recuperar el índice y seleccionar el `RouteResult`
original, de modo que mapa/tarjeta/detalles usan el mismo resultado sin alterar
métricas ni geometría. `route()` no se utiliza como fallback.

`MobilityRecommendationSummary` presenta «Ruta sugerida» y las razones del motor.
`RouteResultCard` conserva «Ruta seleccionada» para el resultado vigente.
Al elegir una alternativa, el resumen cambia a «Selección manual» y distingue el
número elegido de la sugerencia original. Las razones quedan atribuidas a esa
sugerencia, no a la nueva selección. Elegir manualmente la misma sugerida también
se reconoce como decisión manual. No se vuelve a consultar ningún proveedor.

Una sola candidata conserva el mensaje del selector y se explica como única
alternativa vehicular elegible recibida. No se asegura que sea la única ruta
existente en el mundo ni que OSRM siempre entregue varias alternativas.

## Errores, invalidación y concurrencia

Al recalcular se eliminan selección, sugerencia y aviso anterior. Error OSRM,
respuesta vacía, preferencias incompatibles o fallo de almacenamiento no dejan
resultados anteriores presentados como vigentes. Los textos/puntos siguen
disponibles para modificar o reintentar; no se agregan preferencias ni overrides.

Edición real, cambio GPS/manual y cambio de coordenadas invalidan la decisión.
Cursor/composición sin cambio de texto conservan el resultado. Cada espera de
geocodificación, OSRM, preferencias y motor comprueba `mounted` e identificador
del cálculo. Respuestas obsoletas y posteriores a dispose no pueden seleccionar
una ruta ni finalizar una carga más reciente. El selector previo conserva sus
protecciones de cierre e identidad de cálculo.

## Pruebas y límites de validación

- Motor: mínimos, desempates, única/vacío, elegibilidad, identidades duplicadas,
  métricas inválidas, unidades sin redondeo, preservación y condiciones desconocidas.
- Resumen: sugerencia frente a selección manual, retorno manual a la sugerida,
  semántica y 320/390/768/1440 px con texto al 150 %.
- Home/panel: recomendación inicial distinta de la primera del proveedor, mapa/
  tarjeta/detalles sincronizados, cambio manual sin consultas, default explícito,
  preferencias con/sin driving, relectura y fallo de almacenamiento, edición,
  GPS, OSRM fallido y respuestas tardías de preferencias/motor.

Los tests usan almacenamiento simulado y servicios controlados, sin HTTP real.
No acreditan disponibilidad remota de OSRM, durabilidad nativa de preferencias,
OAuth, RLS ni ejecución Android/iOS. No se modifican archivos fuera del alcance
autorizado ni los módulos asignados a Brayan.

## Validación de la entrega

- `dart format` sobre los ocho Dart creados/modificados: completado.
- `flutter analyze --no-pub`: sin incidencias, salida 0.
- `flutter test --no-pub --reporter expanded`: 206 pruebas aprobadas, salida 0.
  Baseline: 180; se añaden 14 del motor, 6 del resumen y 6 de integración.
  Las 17 regresiones previas de Home se conservan y se adaptan a la selección
  inicial del motor (23 pruebas de flujo Home en total).
- `git diff --check`: sin errores.
- Sin cambios en dependencias, HomeScreen, RutasScreen, formularios, selector,
  tarjeta, pantalla/servicio de preferencias ni matriz de requisitos.
- Sin commit, push, PR, merge, rebase ni cherry-pick.
