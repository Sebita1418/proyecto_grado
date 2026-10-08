# Orientación histórica de horarios

## Alcance y baseline

Rama `feature/historical-departure-guidance`, baseline `93d1664` (movilidad
multimodal real). Se comprobó árbol limpio antes de editar. Este incremento
añade observaciones históricas al flujo Programar, sin pronósticos, cálculo de
demora ni elección automática de hora. No altera Ahora/Programar, routing,
selección de rutas, Navigation V2 o VehicleRecommendationEngine.

## Fuente reutilizada y privacidad

Se reutilizan `MobilityAnalyticsRepository`, `SupabaseMobilityAnalyticsRepository`,
`MobilityAnalyticsQuery`, `AnalyticsBatch` y `AnalyticsObservation`. Una única
consulta cubre los últimos 30 días respecto del reloj del controlador; el
timestamp de evaluación del servidor se conserva. No se consulta el futuro.

La RPC existente `public.mobility_analytics_observations` proporciona timestamps
individuales, `truncated`, `evaluated_at`, versión y campos minimizados. Esos
timestamps permiten agrupar por calendario local; no se usan los buckets diarios
UTC de la pantalla analytics, porque perderían el detalle horario necesario.
No se crean consultas SQL alternativas ni se modifican RPC, RLS o permisos.
No se ejecutó SQL remoto ni se certifica que la RPC esté desplegada.

La respuesta solo necesita tipo, creación, expiración y estado. La orientación
cuenta creaciones de reportes conservados de todas las categorías/estados, incluidos
cancelados: describe publicación registrada, no vigencia del incidente ni
confirmación de un evento. No transmite el origen/destino a la RPC. No copia
identidades, coordenadas, descripciones, rutas ni historiales individuales al
resultado de orientación. La UI presenta conteos agregados y fechas de cobertura.

**Es historial general de los registros disponibles, sin delimitación geográfica
respecto de la ruta del usuario.** No se afirma que describa esa vía, zona o modo.
La ausencia de esos datos en la proyección impide una orientación específica por
trayecto; se informa expresamente en la tarjeta.

## Calendario America/Bogota

`BogotaCalendar` convierte cada instante UTC a campos civiles America/Bogota
mediante UTC−05. Usa contenedores UTC desplazados únicamente para comparar
campos/fechas, sin reinterpretarlos como instantes reales. No depende de la zona
del dispositivo para agrupar. La fecha/hora elegida sigue siendo el instante
original de `DepartureTimeContext`; la tarjeta muestra explícitamente su franja
en America/Bogota, incluso si el selector usa otra zona del dispositivo.

El alcance es moderno (inicio de consulta y selección desde el año 2000). La
[base de zonas IANA, sección Colombia](https://raw.githubusercontent.com/eggert/tz/main/southamerica)
documenta UTC−05 y el último cambio estacional de 1993. No se incorpora un
calendario histórico universal ni una dependencia nueva. Si cambian las reglas
de America/Bogota, deberá revisarse esta conversión; tampoco se pretende
anticipar futuros cambios legislativos de zona horaria.

## Procesamiento y denominadores

Consulta `[inicio, fin)` UTC: incluye inicio, excluye fin. Solo se comparan días
locales íntegros incluidos en el intervalo y terminados al evaluar el servidor.
Las fechas inicial/final parcialmente cubiertas no aportan conteos ni exposiciones
al análisis por franjas. La muestra total del periodo y la muestra usada en días
completos se presentan por separado.

Se generan 168 métricas (7 días de semana × 24 horas). Para cada métrica:

- observaciones de creación de reportes dentro de esa hora y día de semana;
- número de fechas locales completas de ese día de semana en el intervalo;
- número de esas fechas con al menos un reporte en la franja.

Ejemplo de interpretación: «4 reportes / 4 fechas» expresa el total acumulado
en cuatro ocurrencias históricas de esa hora. No estima cuatro reportes para una
fecha futura. Todos los buckets horarios del mismo día de semana tienen el mismo
denominador de fechas; compararlos por total no introduce una diferencia de
exposición. No se calculan porcentajes de confianza, tráfico ni velocidades.

## Condiciones exactas para mostrar orientación

Se usa el día de semana de la fecha/hora programada solo para seleccionar qué
fechas **pasadas** comparar. El evaluador muestra «Menor actividad histórica de
reportes» únicamente cuando se cumplen todas estas condiciones:

| Condición | Umbral o regla |
|---|---|
| Integridad de consulta | Sin truncamiento ni filas inválidas/fuera de periodo; fin no posterior a evaluación del servidor |
| Calendario | Inicio y selección dentro del alcance moderno America/Bogota |
| Cobertura temporal | Al menos 28 días locales completos |
| Muestra global | Al menos 100 reportes en los días completos |
| Repetición del día seleccionado | Al menos 4 fechas completas de ese día de semana |
| Presencia por fecha relevante | Al menos 12 reportes en cada una de esas fechas |
| Presencia por hora | Cada una de las 24 franjas de ese día tiene al menos 4 reportes |
| Repetición por hora | Cada franja tiene reportes en al menos 3 fechas distintas |
| Diferencia observada | Alguna franja tiene menos reportes que otra; no se orienta ante igualdad de las 24 |

Son criterios conservadores de ingeniería **no validados como metodología de
inferencia estadística o representatividad poblacional**. No deben presentarse
como niveles de confianza. Exigir muestra en todas las horas evita elegir como
favorable una franja sin registros o una única observación aislada. La exigencia
por fecha reduce resultados dominados por una sola jornada. Puede hacer que la
orientación no esté disponible frecuentemente; esa insuficiencia es intencional.

Cuando se cumplen los umbrales, se muestran todas las franjas empatadas con el
conteo mínimo dentro del mismo día de semana, en orden horario. No se escoge una
hora «mejor» arbitrariamente ni se modifica la selección del usuario. La lista
se expande a demanda para mantener la tarjeta compacta.

## Estados, cobertura y límites de interpretación

- Error de red, permisos, contrato o RPC ausente: «Datos históricos no disponibles»,
  Reintentar. No se crea un resultado con cero observaciones.
- Consulta exitosa sin registros: «Sin reportes registrados en el periodo
  consultado» y «Datos insuficientes para orientar horarios».
- Datos parciales: se indican truncamiento/exclusiones; se bloquea orientación,
  aunque el número recibido sea grande.
- Muestra/cobertura insuficiente o sin diferencia: se informa insuficiencia y
  se conserva periodo, tamaño de muestra y fechas comparadas.
- Resultado observado: franjas de menor actividad registrada, periodo exacto,
  denominador, muestra y advertencia permanente.

«Consulta completa de registros disponibles» significa que el contrato entregó
sin truncamiento los registros retenidos visibles por la RPC. **No certifica
captura ininterrumpida, ausencia de borrados o retención completa**. El esquema
original permite borrado en cascada al eliminar usuarios; los reportes son
comunitarios y no una muestra controlada. Una fecha sin registros no demuestra
ausencia de circulación. Los umbrales no resuelven esos sesgos.

No se extrapolan valores fuera de las fechas observadas. La etiqueta del día
elegido enlaza un calendario de comparación, no una predicción para la fecha
programada. No se denomina «menos tráfico», «hora óptima» o «mejor horario» a la
actividad mínima. Se muestra: «Cero reportes no significa cero tráfico».

## Arquitectura e integración

Repositorio analítico existente → batch y consulta existentes →
`HistoricalDepartureGuidanceEvaluator` → resultado agregado inmutable →
`HistoricalDepartureGuidanceController` → `HistoricalDepartureGuidanceCard`.

El evaluador es Dart puro, determinista, sin reloj/red/Flutter/Supabase. El
controlador inyecta repositorio/reloj y ofrece idle/loading/data/error, retry,
descarte de respuestas antiguas y protección tras dispose. La tarjeta distingue
los estados de evidencia dentro de data.

Mientras una consulta está pendiente, cambiar la selección reutiliza la misma
consulta y evalúa al terminar la selección más reciente. Con datos en memoria,
cambios de fecha/hora se reevaluan sin otra consulta durante 10 minutos. Retry
fuerza lectura nueva e invalida las respuestas previas. El cache vive solo mientras
la tarjeta esté montada; volver a Ahora la destruye. El periodo y actualización
reales siempre se muestran, también si los datos proceden de cache.

`MapSearchPanel` solo añade un repositorio analítico opcional para tests y la
tarjeta cuando Programar está activo. La tarjeta recibe exclusivamente el
instante seleccionado. No invoca OSRM, no cambia rutas ni llama navegación.
No se altera `departure_time_selector.dart`, ni las reglas temporales existentes,
VehicleRecommendationEngine, recomendación multimodal o servicios operacionales.
La RPC requiere sesión autenticada conforme al contrato existente.

Se reutiliza `MobilityDesign`, tema y tarjetas. Se verifican anchos 320, 390,
768 y 1440, con escalas de texto 1× y 2×, sin overflow en los escenarios probados.

## Tráfico real opcional

La inspección encontró una utilidad heredada `GoogleRoutesService` con
`TRAFFIC_AWARE`, pero exige `GOOGLE_ROUTES_API_KEY`, no aporta un dataset temporal
por franja y no forma parte del routing productivo actual. El código disponible
no demuestra autorización, cobertura local ni acceso sin requisitos adicionales.
No se reactivó ni se solicitaron credenciales. No se integraron nuevas APIs,
scrapers ni endpoints de tráfico. OSRM sigue siendo routing, no tráfico en vivo.

Por tanto el bloque se completa con reportes históricos, y tráfico real queda
como limitación de fuente. No se confunden conteos de incidentes con vehículos,
velocidad, demanda o congestión.

## Pruebas y resultados

- `test/mobility/analytics/historical_departure_guidance_test.dart`: ocho casos
  de calendario/cambio de día y hora, cobertura, suficiencia, ceros, parcial,
  límites, determinismo, inmutabilidad, minimización, cache, retry y concurrencia.
- `test/widgets/historical_departure_guidance_test.dart`: once casos; ocho
  combinaciones de ancho/texto, estados, selección actualizada y prueba de
  integración Programar preservando ruta/fecha y cero llamadas adicionales a
  cualquiera de los tres servicios de routing o inicio de navegación.
- Pruebas nuevas focalizadas: **19 passed**.
- Regresiones analytics, decisión/Home, incidentes y multimodal: **45 passed**.
- `flutter analyze --no-pub`: **No issues found!**.
- `flutter test --no-pub`: **543 passed**, sin fallos.
- `git diff --check`: limpio en la revisión final.

Los tests usan repositorios y routing simulados; fixtures solo en tests. No se
consultó Supabase remoto para validar el feature. Las pruebas certifican reglas
implementadas, integración y estados, no representatividad de registros reales.

## Impacto en OE3 y limitaciones académicas

Se incorpora una observación temporal trazable en Programar: periodo, muestra,
calendario local, reglas explícitas y estados de insuficiencia. Esto fortalece
evidencia funcional sobre orientación de horarios a partir de registros reales,
sin afirmar recomendación predictiva de horarios o cumplimiento pleno de OE3.

Siguen pendientes validación empírica de umbrales, retención, calidad, sesgos de
participación, cobertura geográfica/por modo y fuentes instrumentales de tráfico.
El bloque no garantiza una salida con menos tráfico, menor tiempo o mayor seguridad,
ni añade IA/ML, predicción o capacidad Big Data masiva. No modifica SQL/RLS/RPC,
no expone identidad y no redacta todavía FDC-125.
