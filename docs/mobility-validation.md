# Validación funcional y relevancia de movilidad

## Propósito, baseline y alcance

Baseline `06c5c6b` (`feat: add historical mobility analytics (#50)`), rama
`feature/mobility-validation`. Se comprobó árbol limpio y diff check antes de
editar. Este bloque observa decisiones productivas ya calculadas, permite
inspeccionar restricciones y comparaciones y ofrece evidencia reproducible para
los objetivos de recomendación, explicación y validación funcional del proyecto.
No implementa nuevas rutas, consultas ni modifica el algoritmo productivo.

La validación evalúa consistencia con reglas implementadas, no la corrección
empírica del proveedor, satisfacción del usuario o resultados en tránsito real.

## Auditoría del motor y del flujo real

`VehicleRecommendationEngine` es la fuente de decisión. Recibe `MobilityContext`
y las `RouteOption` en orden del proveedor. Revalida endpoints, métricas y IDs;
solo admite driving permitido por las preferencias. Si no hay candidatas,
lanza `NoEligibleVehicleRouteException`. No produce una ruta nueva.

Primero busca duración mínima, usando distancia mínima ante duración igual.
Conserva el orden de entrada ante igualdad de ambas métricas. Si cada alternativa
elegible tiene una `RouteIncidentAnalysis` con ID coincidente, forma un grupo
comparable respecto de esa referencia: duración <= 1.25 veces y distancia <=
1.5 veces. Dentro de ese grupo, prioriza alternativas sin cierres si existe
alguna; después minimiza el número de reportes próximos. Entre esos finalistas
aplica duración, distancia y orden del proveedor. Si falta evidencia, se limita
a duración y distancia: desconocido no es evidencia favorable de ausencia.

Se extrajeron solamente los dos límites a `VehicleRecommendationPolicy`, un
archivo Dart puro. Las constantes públicas del motor conservan nombre y valor
mediante alias const. No se modificaron filtros, ranking, razones ni recursión.

OSRM entrega `RouteResult` con segundos/metros sin ajuste por reportes.
`RouteInsight` presenta razones y análisis coincidente con la ruta sugerida.
`CurrentMobilityDecisionAdapter` distingue disponibilidad de rutas, condiciones
y modos, y `MobilityDecisionResult` distingue evaluación de modos de falta de
recomendación. Esos componentes se conservaron.

`MapSearchPanel` conserva `_options` en orden OSRM, `_recommendation`, índices
separados de sugerida/seleccionada y `_manuallySelected`. Inicialmente selecciona
la primera alternativa recibida; eso puede diferir de la sugerida sin constituir
selección manual. Los cambios de reportes actualizan la recomendación y conservan
la selección/geométría. La validación captura esos campos y los snapshots ya
disponibles; no usa analítica histórica ni convierte reportes en tráfico.

## Arquitectura

Resultado y contexto productivos → `CurrentMobilityValidationAdapter` →
`MobilityValidationInput` → `MobilityValidationEvaluator` →
`MobilityValidationSnapshot` → `MobilityValidationScreen`.

El adaptador proyecta IDs técnicos, orden del proveedor, elegibilidad, segundos,
metros, fuente, conteos agregados, razones y fecha de evaluación del motor.
No copia geometrías, identidades, coordenadas ni descripciones de reportes.
Reutiliza los totales/categorías de `RouteIncidentAnalysis`; no analiza geometría.

El evaluador y su modelo importan solo la política Dart pura: no Flutter,
Supabase, reloj ni red. Sus comparaciones independientes verifican restricciones
de cada etapa sobre la salida recibida; no invocan el motor, no eligen una ruta
ni cambian el resultado. Reutilizan los umbrales de la política para evitar
divergencia por constantes duplicadas. La independencia de los checks permite
detectar decisiones alteradas, en vez de comparar el resultado consigo mismo.

Input y snapshot contienen campos finales y listas inmutables; las proyecciones
también son inmutables. Al reordenar la lista proyectada, `providerOrder` conserva
el orden original y el resultado de validación no cambia. Reordenar realmente
las alternativas antes de ejecutar el motor sí puede cambiar un desempate: es
parte explícita de la regla del proveedor. No se ordenan arbitrariamente por ID.

## Criterios y estados

Cada criterio admite PASS, FAIL, UNKNOWN y NOT_APPLICABLE. General:

- `consistent`: sin FAIL ni UNKNOWN en los criterios evaluados.
- `inconsistent`: al menos un FAIL comprobable.
- `incomplete`: decisión recibida con criterios UNKNOWN.
- `noRecommendation`: salida ausente sin inconsistencia comprobada; no equivale
  a error técnico. Si no hay candidatas elegibles, se explica esa circunstancia.
  Si hay candidatas pero falta decisión, su causa queda UNKNOWN; no se inventa
  que el motor no tenía alternativas.

UNKNOWN nunca se transforma en PASS. NOT_APPLICABLE se usa para comparaciones
sin pares, ausencia de alternativas sin cierres o desempates que no se activan.
El check finalista asegura pertenencia aun si un check comparativo no aplica.
La marca sugerida se compara con la salida recibida del motor; las restricciones
independientes comprueban esa salida contra el conjunto original.

Se verifican los factores `duration`, `distance`, `conditions` contra sus datos y
checks. Otros factores o texto libre quedan no evaluables: no hay análisis
semántico automático que certifique una frase arbitraria. Por eso decisiones
correctas pueden quedar `incomplete`, especialmente con razones `other` del
motor (límites provisionales, ruta única u orden estable). Los checks técnicos
correspondientes sí se muestran por separado con su resultado comprobado.

## Métricas de relevancia

Rankings por duración/distancia sobre alternativas elegibles: `1 + cantidad con
valor estrictamente menor`. Los empates comparten rango, con posibles saltos.
Diferencia porcentual: `(valor sugerido - mínimo observado) / mínimo * 100`.
Para referencia cero: ambos cero → 0 %; sugerida positiva → no evaluable. Valores
no finitos no se publican como porcentaje. No son confianza, precisión ni score.

Se presentan cantidad evaluada (cero sin salida), alternativas recibidas,
comparables (solo con evidencia completa), duración/distancia sugeridas,
reportes/cierres en la sugerida y suma de proximidades por alternativa elegible.
Un reporte próximo a dos rutas cuenta dos veces en esa suma: no se afirma que
sea un número de reportes únicos. Sin todos los snapshots, la suma es UNKNOWN.
Las medidas describen el conjunto recibido, no todas las rutas posibles.

## Matriz de validación

| Criterio | Datos utilizados | Regla | Resultado posible | Limitación |
|---|---|---|---|---|
| Elegibilidad | Modo, preferencias, ID de salida | Sugerida pertenece a candidatas driving permitidas | PASS/FAIL/UNKNOWN/NA | No valida otros modos |
| Marca sugerida | ID marcado e ID salida | Deben coincidir | PASS/FAIL | No evalúa la selección del usuario |
| Conjunto | IDs originales y IDs recomendación/alternativas | Igual conjunto elegible, sin duplicados | PASS/FAIL/UNKNOWN | Solo alternativas recibidas |
| Métricas | Segundos/metros originales y salida | Igualdad sin ajuste | PASS/FAIL/UNKNOWN | No confirma tiempos reales |
| Evidencia | Snapshots coincidentes por ID | Todos presentes para comparar exposición | PASS/UNKNOWN/NA | No certifica frescura/retención remota |
| Comparable | Referencia mínima y umbrales compartidos | <=1.25 duración y <=1.5 distancia | PASS/FAIL/UNKNOWN | Regla provisional, no velocidad/tráfico |
| Cierres | Conteos en grupo comparable | Si existen rutas sin cierres, sugerida pertenece a ellas | PASS/FAIL/UNKNOWN/NA | Proximidad no confirma bloqueo |
| Exposición | Totales en grupo prioritario | Sugerida en el mínimo observado | PASS/FAIL/UNKNOWN | No transforma conteos en demora |
| Duración | Segundos finalistas | Mínimo entre finalistas | PASS/FAIL/UNKNOWN/NA | Puede ser mayor al mínimo global |
| Distancia | Metros en empate de duración | Mínimo entre empatadas | PASS/FAIL/UNKNOWN/NA | No es objetivo primario |
| Orden | Índice original en empate completo | Primera del proveedor | PASS/FAIL/UNKNOWN/NA | Cambia si cambia el orden original |
| Finalista | Restricciones anteriores | Salida pertenece al grupo final por métricas | PASS/FAIL/UNKNOWN | No elige ni reemplaza salida |
| Razones | Factor y checks/evidencia | Factor respaldado por su etapa | PASS/FAIL/UNKNOWN/NA | Texto libre no certificado |
| Selección | ID seleccionado e IDs recibidos | Selección conocida y conservada por separado | PASS/FAIL/UNKNOWN | Elegir otra no invalida sugerencia |

## UI e integración

Botón secundario «Validación de recomendación» en el resultado del planificador,
fuera del resumen principal. Disponible con opciones recibidas, periodo actual
y sin actualización de recomendación en curso. No se ofrece como validación
predictiva de una salida futura. Abre una pantalla con snapshot calculado en
memoria al pulsar; no altera Home, mapa, selección ni navegación. Volver conserva
el flujo. No se ha añadido acceso al Drawer ni nuevas consultas.

La pantalla usa el tema heredado y `MobilityDesign`: tarjetas con radio 20,
inset 16, tipografía/colores de la aplicación, scroll y ancho máximo 960.
Secciones: resumen, criterios, comparación, evidencia y razones originales.
Estados con texto además de símbolos; la información puede ocupar varias líneas.
La pantalla captura el momento de apertura; no promete actualización en vivo.

## Pruebas y evidencia para el informe

`test/mobility/validation/mobility_validation_test.dart` cubre una y varias
alternativas, rápida/no rápida, corta/no corta, cierres, exposición, límites
exactos, desconocidos, empates, selección manual, sin recomendación, orden,
reordenamiento del DTO, determinismo, porcentajes y cero. Prueba equivalencia
de constantes tras su extracción. Ejecuta el motor productivo en matrices
controladas y después evalúa sin copiar su expected al evaluador. También
altera salida/marca/métricas/conjunto para verificar detección de divergencias.

`test/screens/validation/mobility_validation_screen_test.dart` cubre la pantalla
a 320/390/768/1440, scroll sin excepciones, selección diferente, unknown, una ruta,
varias rutas y sin recomendación. Una prueba de integración abre la pantalla
desde `MapSearchPanel`, verifica IDs/selección, vuelve y comprueba que no hay
nuevas peticiones OSRM ni eventos de cambio de ruta. Fixtures solo en tests.

Se intentó el formato con la lista explícita de archivos modificados. Quedó sin
salida aproximadamente 20 segundos y se interrumpió según la instrucción del
bloque. No se repitió ni se iniciaron tests nuevos, regresiones, analyze o suite.
Esos checks quedan pendientes; no se certifican compilación, responsive ni tests
verdes. `git diff --check` pasó. Comandos para validación local:

```powershell
dart format lib/mobility/vehicle_recommendation_policy.dart lib/mobility/vehicle_recommendation_engine.dart lib/mobility/validation/mobility_validation.dart lib/mobility/validation/current_mobility_validation_adapter.dart lib/screens/validation/mobility_validation_screen.dart lib/widgets/map_search_panel.dart test/mobility/validation/mobility_validation_test.dart test/screens/validation/mobility_validation_screen_test.dart
flutter test --no-pub test/mobility/validation test/screens/validation
flutter test --no-pub test/mobility/vehicle_recommendation_engine_test.dart test/mobility/route_incident_analysis_test.dart test/widgets/mobility_recommendation_summary_test.dart test/screens/home/route_flow_test.dart test/screens/home/incident_route_flow_test.dart test/screens/home/mobility_decision_experience_test.dart test/screens/home/map_experience_v2_test.dart
flutter analyze --no-pub
flutter test --no-pub
git diff --check
git status --short
```

Se pueden citar posteriormente reglas, matriz, fixtures, pruebas ejecutadas con
su resultado real, comparaciones calculadas, casos límite y UI. No se redacta
FDC-125 en este bloque ni se convierte consistencia funcional en eficacia real.

## Limitaciones e interpretación académica

El evaluador no repite validación geométrica ni consulta nuevos incidentes.
No verifica la veracidad de reportes, el estado actual de la vía o frescura de
datos remotos; observa snapshots existentes. No se recalcula proximidad.
El conteo de candidatos elegibles se toma del conjunto entregado a este flujo;
no mide alternativas del mundo real ni calidad de cobertura del proveedor.

Validación consistente no significa óptima, garantizada o segura. Faltan pruebas
empíricas, evaluación con usuarios, cobertura de proveedores y mediciones de
impacto. No se afirma IA, predicción, precisión porcentual ni Big Data adicional.
No se modifican SQL, Supabase, routing, OAuth, Navigation V2 o recomendación.
Este bloque aporta observabilidad de reglas y evidencia de consistencia
funcional, separada de análisis histórico y de una evaluación de eficacia real.
