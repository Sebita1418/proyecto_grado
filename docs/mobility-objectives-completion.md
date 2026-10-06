# Mobility Objectives Completion

Este documento registra el alcance funcional del incremento `mobility-objectives-completion` en la rama `feature/mobility-objectives-completion`. Describe el comportamiento implementado y sus límites a partir del código del repositorio. La evidencia de validación corresponde al estado local de la rama informado por Sebastián antes del commit final; no representa una verificación de servicios remotos ni una certificación académica de cumplimiento total.

## 1. Objetivo del incremento

El incremento cierra una brecha de integración entre la planificación vehicular que ya calculaba rutas y la experiencia de decisión mostrada en el mapa. Incorpora un contexto explícito de salida, representa los medios disponibles y no disponibles, conecta el resultado vehicular existente con una capa de decisión tipada, muestra información de soporte y conserva la distinción entre la alternativa sugerida y la que el usuario selecciona.

El resultado consolida el recorrido de consulta, evaluación, comparación y selección en la experiencia productiva del mapa. No añade evaluación productiva multimodal ni predicciones temporales: esas capacidades siguen fuera del alcance disponible.

## 2. Arquitectura del flujo productivo

El flujo efectivo, para un viaje vehicular con salida inmediata, es:

`origen/GPS → destino → momento del viaje → medio de transporte → routing → alternativas → análisis de reportes → recomendación → selección → navegación`.

Sus responsabilidades se distribuyen entre componentes:

1. `HomeScreen` mantiene el mapa, la ubicación y el ciclo de vida de navegación; entrega servicios y callbacks al panel.
2. `MapSearchPanel` coordina el formulario, las consultas de ubicación/direcciones, el cálculo de rutas y el estado de alternativas, evidencia, recomendación y selección.
3. `GeolocatorGateway`, `PlaceSuggestionService`, `GeocodingService` y `OsrmRoutingService` realizan, respectivamente, el acceso a GPS, las sugerencias, la resolución explícita de direcciones y el routing.
4. Las rutas se envuelven en `RouteOption` y se combinan con `MobilityContext`. `RouteIncidentAnalyzer` procesa snapshots locales de reportes para cada alternativa.
5. `VehicleRecommendationEngine` produce la sugerencia vehicular y sus motivos. `CurrentMobilityDecisionAdapter` y `MobilityDecisionCoordinator` expresan el contexto/capacidad y conectan ese resultado con la presentación.
6. `RouteAlternativesSelector`, `RouteResultCard`, `RouteInsight` y `MobilityRecommendationSummary` representan alternativas, ruta activa, motivos y evidencia.
7. Cuando el usuario inicia el recorrido, `NavigationSession` consume la ruta validada y las posiciones GPS para actualizar progreso e instrucciones.

La secuencia es una descripción de responsabilidades, no una clase monolítica: las consultas de red, el análisis espacial, la decisión y la interfaz pertenecen a componentes separados.

## 3. MapSearchPanel

`MapSearchPanel` sigue siendo la experiencia productiva principal de planificación y análisis de movilidad sobre el mapa. Mantiene el estado temporal del formulario y coordina sus servicios inyectables, controla solicitudes pendientes y obsoletas, prepara las alternativas para presentación y comunica cambios de ruta a `HomeScreen`.

El panel no implementa por sí solo los proveedores ni el algoritmo de recomendación. Delega sugerencias, geocodificación, routing, análisis espacial, preferencias y evaluación a sus servicios y componentes de dominio. El panel impide calcular si el contexto temporal es programado y aplica las guardas que habilitan la navegación. `HomeScreen` conserva la sesión de navegación y la composición general del mapa.

## 4. Contexto temporal

`DepartureTimeContext` expresa un instante y un tipo (`now` o `scheduled`). El selector compartido ofrece **Ahora** y **Programar**; cuando ya existe un horario, el control de programación se presenta como **Cambiar horario**.

**Ahora** conserva el flujo vigente: permite solicitar routing disponible, obtener una recomendación con los datos actuales, elegir una alternativa e iniciar navegación si se satisfacen sus guardas.

**Programar** conserva la fecha y hora futuras como intención temporal. No consulta predicciones de tráfico, no calcula condiciones futuras ni crea una reserva o alerta. El panel no solicita routing al calcular mientras el contexto esté programado. Si ya existe una ruta de una consulta realizada en Ahora, puede permanecer visible como referencia de información actual; no se presenta como predicción para la hora seleccionada y se deshabilita el inicio de navegación.

**Programar → Ahora** actualiza el contexto temporal. Si siguen vigentes las coordenadas, alternativas y recomendación del cálculo anterior, puede restablecerse la decisión actual sin repetir automáticamente la consulta OSRM. Una edición del viaje o un cambio de posición que invalide ese contexto requiere el flujo de cálculo correspondiente.

## 5. Selector temporal

`lib/widgets/departure_time_selector.dart` contiene el selector reutilizable de salida y la presentación del aviso de falta de predicciones. `lib/widgets/mobility_planner/departure_time_selector.dart` conserva una ruta de importación compatible que reexporta el selector compartido.

Esta organización evita mantener dos implementaciones de la misma interfaz temporal mientras los callers existentes adoptan el componente común. La reexportación preserva compatibilidad de imports; no implica que todo el código legado relacionado con planificación haya sido eliminado.

## 6. Medios de transporte

El dominio representa cuatro modos conceptuales: vehículo (`driving`), caminando (`walking`), bicicleta (`cycling`) y transporte público (`publicTransport`). Su representación en el selector no significa que todos tengan proveedores productivos.

- **Vehículo:** dispone del routing productivo actual mediante OSRM.
- **Caminando:** no cuenta con proveedor ni routing productivo integrado en este flujo.
- **Bicicleta:** no cuenta con proveedor ni routing productivo integrado en este flujo.
- **Transporte público:** no cuenta con routing, datos de rutas ni horarios productivos integrados.

La interfaz muestra estos límites mediante estados textuales y, cuando corresponde, mensajes al intentar seleccionar un medio no disponible. No reutiliza una ruta vehicular como si fuera una ruta de otro modo ni presenta métricas multimodales simuladas.

## 7. Routing

`OsrmRoutingService` solicita perfiles de conducción (`driving`). El flujo de alternativas usa `alternatives=true`, geometría completa GeoJSON y pasos (`steps=true`). La respuesta puede contener una o varias rutas; OSRM puede devolver una sola aunque se soliciten alternativas.

Para cada ruta válida, el código conserva geometría, distancia en metros y duración estimada en segundos. Cuando la respuesta contiene pasos utilizables, se transforman en instrucciones de maniobra; ante pasos ausentes o inválidos, la ruta puede conservarse sin fabricar instrucciones. La selección vehicular y la tarjeta trabajan con las rutas recibidas del proveedor.

La duración entregada por OSRM es una estimación de la ruta. En este incremento no se interpreta como tráfico observado en tiempo real ni se ajusta con retrasos inferidos de reportes.

## 8. Motor de recomendación

`VehicleRecommendationEngine` es un **MOTOR DE RECOMENDACIÓN DETERMINISTA Y EXPLICABLE** para las alternativas vehiculares elegibles recibidas. Valida la consistencia de los identificadores, extremos, geometría y métricas. Sin análisis completo de reportes coincidente para las alternativas, compara primero duración estimada; ante empate exacto usa distancia, y si ambas métricas empatan conserva el orden del proveedor.

Cuando todas las alternativas vehiculares tienen un snapshot de análisis coincidente, aplica la regla espacial de exposición dentro del grupo comparable: hasta 25 % más de duración y 50 % más de distancia que la alternativa más rápida. Considera la presencia de cierres reportados y el conteo de reportes próximos en ese grupo, y mantiene duración/distancia como criterio de desempate. Las razones explican el resultado y las reglas aplicadas. Esta política es determinista para las mismas entradas y orden del proveedor.

El motor no usa IA ni Machine Learning, no es un modelo predictivo, no calcula demoras a partir de proximidad y no garantiza una ruta óptima global. Tampoco afirma una preferencia personal del usuario por distancia o duración.

## 9. Mobility Decision

`CurrentMobilityDecisionAdapter` adapta el viaje, el contexto temporal, las rutas y los snapshots existentes a las capacidades actuales por modo y a la disponibilidad de datos. No consulta proveedores ni solicita ubicaciones.

`MobilityDecisionContext` reúne `MobilityContext`, `DepartureTimeContext` y las opciones con sus capacidades y estados de evidencia. `MobilityDecisionCoordinator` conecta esa información con la recomendación vehicular que le entrega el caller. Envuelve el resultado existente o explica por qué no hay recomendación; no hace routing, fetch, scoring ni ranking por sí mismo.

`MobilityDecisionResult` representa la decisión recomendada o la ausencia de recomendación y registra qué modos fueron evaluados. Esta capa tipada permite que la interfaz explique capacidades y datos sin atribuir al coordinador trabajo que corresponde a los servicios o al motor.

## 10. RouteInsight

`RouteInsight` presenta información derivada de una `MobilityRecommendation` y del análisis cuyo identificador coincide con la ruta sugerida. Calcula la duración y distancia mostradas, conteos de reportes/cierres cuando existe un snapshot y textos explicativos basados en los motivos del motor. No consulta datos ni vuelve a clasificar rutas.

La **alternativa sugerida** es la seleccionada por el motor. La **alternativa seleccionada** es la que está activa en el mapa y puede cambiar por acción manual. La interfaz informa ambas por separado. Una selección manual no modifica retroactivamente la recomendación ni reasigna sus motivos a la ruta elegida; seleccionar otra alternativa tampoco requiere volver a consultar routing.

## 11. Evidencia de movilidad

La presentación compacta de `MobilityRecommendationSummary` expone, al abrir los motivos, la fuente de métricas y el estado de reportes viales próximos. El estado de disponibilidad se obtiene del contexto tipado, mientras el conteo visible proviene del snapshot de `RouteInsight` que coincide con la recomendación.

Los estados distinguen evidencia disponible, desconocida, no disponible y parcial. Una fuente **desconocida** se representa como desconocida; **no disponible** indica que no se cuenta con la fuente en esa consulta; **parcial** no permite confirmar ausencia; **disponible** puede describir el conteo observado en el snapshot. Las capacidades sin soporte también se declaran como tales en el selector y el planificador.

**UNKNOWN no equivale a ausencia de problemas.** Tampoco se convierte una fuente no disponible en un conteo cero. La interfaz evita afirmar ausencia de reportes cuando no hay evidencia disponible.

## 12. Reportes viales

`RoadIncidentService` implementa consultas e inserciones contra la tabla `reportes_viales` usando el cliente Supabase disponible en la aplicación. El código valida el borrador y requiere un usuario autenticado para publicar. La consulta obtiene registros activos y limita el conjunto recibido a 100, y el modelo vuelve a verificar estado y expiración con la hora local en UTC.

Las categorías de dominio son accidente, congestión, obra en la vía, vía cerrada, peligro/obstáculo y otro. Cada reporte transporta identificador, usuario, tipo, coordenadas, fecha de creación, fecha de expiración, estado y descripción opcional. `RoadIncidentController` mantiene una lista activa única, refresca ante eventos Supabase Realtime, limita repeticiones con debounce y retira reportes expirados periódicamente.

El mapa presenta marcadores y permite consultar detalles; las vistas de reportes muestran la lista disponible. El código contiene una URL y clave publicable de proyecto, consultas y suscripción Realtime, pero este documento no verifica conectividad, esquema, políticas RLS, permisos ni configuración remota del proyecto.

## 13. Análisis espacial

`RouteIncidentAnalyzer` compara las coordenadas de reportes activos no expirados con los segmentos de la geometría de cada alternativa. Usa una proyección local aproximada y una distancia umbral de 125 metros; descarta coordenadas o geometrías inválidas y duplicados por identificador. Produce un `RouteIncidentAnalysis` con los reportes próximos, su categoría, distancia aproximada y momento de evaluación.

La proximidad espacial de un reporte **no demuestra automáticamente** que una vía esté bloqueada, que el reporte afecte el sentido recorrido o que exista un retraso específico. El análisis no realiza emparejamiento de carriles ni modifica geometría, distancia o duración OSRM. La categoría de cierre es evidencia reportada, no una medición independiente del estado de la vía.

## 14. Realtime

Los eventos de reportes invalidan y refrescan la lista activa mediante el controlador existente. Cuando `MapSearchPanel` recibe un snapshot actualizado, vuelve a analizar las alternativas y solicita una recomendación sobre los datos de reportes actualizados. Este ciclo no requiere automáticamente otra consulta OSRM: el test de flujo confirma que el evento de reportes conserva el número de llamadas de routing.

La actualización reemplaza la sugerencia y la evidencia, pero conserva la ruta/selección manual y la geometría vigente cuando siguen siendo válidas. Las respuestas de análisis tardías se protegen con identificadores de evaluación y cálculo para evitar que un resultado obsoleto sobrescriba el snapshot actual. La publicación o recepción de un reporte durante la navegación actualiza la información del mapa; el reroute de navegación está asociado al seguimiento GPS fuera de ruta, no al evento Realtime del reporte.

## 15. Navigation V2

`NavigationSession` inicia seguimiento GPS sobre la ruta seleccionada válida. Con instrucciones utilizables, presenta la siguiente maniobra y la distancia aproximada hasta ella. Proyecta posiciones GPS sobre la geometría para representar progreso, tramos recorrido/restante y distancia restante. La llegada se determina dentro de 40 metros del destino.

El desvío requiere tres fixes consecutivos a más de 60 metros de la geometría. Si hay callback de reroute, se solicita una ruta desde la posición actual al destino original, con una sola operación activa y un cooldown de 30 segundos. La respuesta se valida antes de reemplazar la geometría; si falla, se conserva la ruta previa. No se ejecuta polling de reroute. La duración restante es proporcional a la estimación OSRM original, no un ETA dinámico ni una estimación de tráfico.

Hay guardas en ambos límites: `MapSearchPanel` solo ofrece iniciar navegación con salida **Ahora**, decisión disponible, callback presente y una ruta con geometría y coordenadas válidas; `NavigationSession.start` vuelve a comprobar geometría, coordenadas y métricas. **Programar no inicia navegación futura.** Los modos no soportados no producen rutas ficticias ni habilitan navegación.

La experiencia muestra instrucciones, progreso GPS, estado de llegada, desvío, reroute y destino. El seguimiento puede pausarse al mover el mapa y reanudarse con el control de recentrado. La implementación funciona en primer plano; este alcance no incorpora guía por voz ni ejecución de navegación en segundo plano.

## 16. Diseño Figma

El incremento conserva la experiencia visual mobile-first implementada previamente: mapa principal, panel inferior, planner, selector de medios, cards, resultados, reportes y controles de navegación. El mapa mantiene protagonismo y el panel organiza la entrada del viaje y el resultado en una jerarquía visual continua.

Las referencias visuales de Figma describen composición y jerarquía, no datos de proveedores. Los tiempos, distancias, incidentes y estados mostrados en uso proceden de los servicios o snapshots disponibles; no se presentan valores ilustrativos del diseño como datos reales.

## 17. Responsive y accesibilidad

La cobertura de widgets incluye anchos de 320, 390, 768 y 1440 píxeles en selectores, planificador, resumen y experiencia Home, con pruebas de escala de texto 1.5x en los componentes correspondientes. Los tests inspeccionan ausencia de excepciones/overflow en esos escenarios y semántica etiquetada para controles y estados seleccionados en selector, planificador y resumen.

Estas pruebas documentan escenarios concretos de layout y semántica. No equivalen a una auditoría completa ni permiten afirmar cumplimiento integral de accesibilidad.

## 18. Proveedores y tecnologías

- **Flutter y Dart:** interfaz, estado de widgets, modelos y lógica de dominio.
- **Supabase:** acceso de aplicación a reportes viales, autenticación usada al publicar y suscripción a cambios Realtime.
- **`flutter_map` y OpenStreetMap:** representación del mapa y capa de tiles con atribución a OpenStreetMap.
- **Geolocator:** permisos, ubicación actual y stream GPS en primer plano.
- **Photon:** proveedor de sugerencias de lugares.
- **Nominatim:** geocodificación explícita de direcciones, no autocompletado por cada tecla.
- **OSRM:** routing vehicular, geometría, métricas estimadas, alternativas y pasos cuando están disponibles.

Las responsabilidades se mantienen separadas: los proveedores entregan datos, los servicios adaptan respuestas, los componentes de dominio validan o evalúan información y la UI la presenta. La disponibilidad y los términos operativos de endpoints públicos externos no quedan garantizados por el repositorio.

## 19. Limitaciones actuales

- El incremento no incorpora IA ni Machine Learning.
- No hay tráfico predictivo ni una fuente integrada de tráfico real.
- No existe predicción de horarios ni evaluación de condiciones futuras.
- **Programar** expresa una intención temporal; no predice condiciones futuras.
- No existe routing productivo para caminando ni bicicleta.
- No existe routing, itinerarios ni horarios productivos de transporte público.
- La duración OSRM no es tráfico real ni una demora estimada a partir de reportes.
- La proximidad de incidentes no demuestra retraso, obstrucción o bloqueo.
- Los endpoints públicos de mapas, geocodificación y routing tienen límites de disponibilidad, cobertura y uso; el prototipo no añade una capa propia que los elimine.
- El código del cliente no demuestra por sí solo el estado remoto de tablas, políticas o canales Realtime de Supabase.
- Big Data y analítica histórica **no quedan resueltos por este incremento**.

## 20. Relación con objetivos académicos

El incremento aporta evidencia implementada para el trabajo de recomendación de rutas vehiculares mediante una regla explicable, procesamiento de alternativas y reportes georreferenciados, manejo explícito del contexto temporal, representación de modos con capacidades diferentes y visualización de información que ayuda al usuario a revisar una sugerencia y tomar una decisión.

La distinción entre sugerencia del motor y selección del usuario mejora la trazabilidad de la decisión en la interfaz. El planner y las señales de disponibilidad hacen visible qué información sustenta el resultado y qué datos faltan.

Este aporte no demuestra por sí solo el cumplimiento total de objetivos académicos, efectividad mediante evaluación de usuarios, desempeño de proveedores en producción ni porcentajes de avance. La evaluación predictiva de horarios y la multimodalidad productiva permanecen pendientes; tampoco se declara resuelto el componente de Big Data/analítica histórica. El documento puede servir como insumo técnico para el contraste posterior de FDC-125, sin sustituir ese contraste.

## 21. Evidencia de validación

Los siguientes resultados fueron confirmados localmente por Sebastián para el estado de la rama `feature/mobility-objectives-completion` previo al commit final:

- `flutter analyze --no-pub`  
  **Resultado:** `No issues found.`
- `flutter test --no-pub`  
  **Resultado:** 475 tests aprobados; `All tests passed.`
- Los tests afectados por las correcciones finales también pasaron en esa validación local.
- `git diff --check`  
  **Resultado:** limpio.

Esta evidencia registra validación local antes del commit final. No implica que los comandos se hayan ejecutado durante la preparación de este documento ni certifica infraestructura remota o despliegue.
