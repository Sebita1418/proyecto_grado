# Contexto de decisión de movilidad

Esta base de dominio contribuye al OE3 del F-DC-124: representar el momento del
desplazamiento, los medios considerados y la evidencia necesaria para futuras
recomendaciones personalizadas. No completa OE3 ni habilita multimodalidad
productiva. No cambia el motor vehicular ni su comportamiento actual.

## Problema y composición

La existencia de un `TransportMode` no implica soporte del producto, datos
suficientes ni una evaluación realizada. Los cinco modelos de
`lib/mobility/decision/` separan esos conceptos, sin consultas, almacenamiento,
reloj implícito, widgets ni nuevas dependencias.

`MobilityDecisionContext` compone el `MobilityContext` existente: reutiliza origen,
destino, condiciones, reportes y `allowedModes`. Este último es el contrato de
modos permitidos que ya consume el motor; la preferencia persistida existente es
un `Set<TransportMode>`. La futura integración debe cargarla y resolver
explícitamente el caso sin preferencias antes de construir el contexto. Esta
capa no carga preferencias, no añade pesos y no decide un fallback.

Las opciones consideradas pueden ser un subconjunto de los modos permitidos,
incluso vacío; nunca pueden estar duplicadas ni fuera de ese conjunto.

## Momento de salida

`DepartureTimeContext.now(at)` y `.scheduled(at)` requieren un `DateTime` no nulo
y conservan el instante y su representación UTC/local. `isNow` e `isScheduled`
expresan la intención; `requestedAt` del viaje sigue siendo el momento de la
solicitud. No se compara la fecha con el reloj: un snapshot histórico sigue
siendo válido y determinista. Dart garantiza el tipo de fecha; la validación de
entrada textual y zona horaria pertenece a quien construye el valor.

Programar una salida no proporciona datos futuros. El contexto rechaza una
opción marcada evaluable para una salida programada sin evidencia temporal
declarada disponible para esa salida. Para representar esa carencia, se incluye
`MobilityDataKind.temporal` en `additionalRequiredData` y se usa
`insufficientData`.

## Disponibilidad de cada medio

| Estado | Soportado | Evaluable |
| --- | --- | --- |
| `evaluable` | Sí | Sí, con requisitos de evidencia satisfechos |
| `insufficientData` | Sí | No; falta evidencia requerida |
| `temporarilyUnavailable` | Sí | No, aunque conserve datos |
| `unsupported` | No | Nunca, aunque existan datos |

No hay un registro automático de capacidades: el llamador debe declararlas
honestamente. Actualmente driving tiene infraestructura real de routing y
recomendación; solo es evaluable cuando sus datos están disponibles. Walking,
cycling y publicTransport deben representarse como `unsupported` en la
integración actual. Tenerlos guardados como preferencia no los habilita.

## Evidencia y calidad

`MobilityDataAvailability` distingue `location`, `routing`,
`durationAndDistance`, `roadConditions`, `temporal` y `transport`. Cada categoría
tiene estado `unknown`, `unavailable`, `partial` o `available`. Una categoría
omitida queda desconocida. Solo `available` satisface un requisito.

La evidencia pertenece a una opción y al contexto de salida evaluado. El mapa
`context.dataAvailability` se deriva por modo de las opciones: los datos de
driving no se propagan a publicTransport. No existe un booleano global que
declare todos los datos suficientes.

La evaluación de una opción de ruta requiere ubicación, routing y
duración/distancia. `additionalRequiredData` permite declarar requisitos del
evaluador futuro (por ejemplo, información del transporte o evidencia temporal)
sin eliminar esos mínimos. `insufficientData` exige alguna carencia entre los
requisitos declarados. Los reportes no son obligatorios para la comparación
vehicular actual por duración/distancia; su ausencia debe seguir visible.

Estos estados describen disponibilidad, no valores: datos de incidentes ausentes
no significan cero incidentes; datos presentes pueden contener cierres; ausencia
de datos temporales no significa condiciones normales. Las mediciones siguen en
los modelos existentes. La ubicación declarada es evidencia utilizable para el
viaje, no necesariamente una lectura GPS; las coordenadas del contexto no
demuestran por sí solas vigencia ni precisión.

## Resultado e invariantes

`MobilityDecisionResult.recommended` conserva una `MobilityRecommendation`
existente, incluidos sus motivos; no crea puntuaciones ni ordena medios.
Requiere que los modos de la ruta recomendada y sus alternativas se hayan
evaluado, sean evaluables y que las rutas correspondan al origen/destino.

`withoutRecommendation` es un resultado normal con razón tipada:
`insufficientEvidence`, `noEvaluableOptions` o `inconclusiveEvaluation`.
La insuficiencia para recomendar entre medios puede existir aunque una opción
individual sea evaluable. Una evaluación inconclusa exige al menos un modo
evaluado; la razón sin opciones evaluables se rechaza si el contexto contiene una.

El llamador declara `evaluatedModes` explícitamente, sin duplicados. El resultado
expone opciones evaluadas, no evaluables (con sus estados y evidencia intactos)
y evaluables todavía no evaluadas. Una recomendación se limita al conjunto
evaluado: no prueba que se hayan comparado todos los modos considerados.
Las colecciones se copian y exponen como inmutables; los estados contradictorios
producen `ArgumentError`, mientras que la ausencia de recomendación no es error.

## Límites y siguiente integración

Los modelos validan coherencia estructural, pero no verifican la procedencia,
vigencia o cobertura temporal de evidencia declarada por el llamador. No
certifican soporte real ni implementan adaptadores de transporte. No hay
horarios, tarifas, predicción, selección de mejor hora ni motor multimodal.

El siguiente paso es un adaptador de dominio que construya el contexto desde
las preferencias y snapshots existentes y envuelva el resultado del motor
vehicular. Debe declarar los otros modos no soportados y conservar las carencias
de datos, sin nuevas consultas para fabricar disponibilidad. Las capacidades
adicionales requerirán proveedores y evaluadores reales antes de habilitarse.
