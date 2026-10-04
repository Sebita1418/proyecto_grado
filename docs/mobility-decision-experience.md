# Experiencia de decisión de movilidad

Este incremento avanza OE3 al conectar el contexto de decisión con la evaluación vehicular existente y mostrar capacidades y evidencia. Avanza OE4 con un planificador progresivo sobre el mapa. OE3 no queda completo: no se incorporan datos temporales futuros ni evaluación productiva de otros medios.

## Flujo y arquitectura

`MapSearchPanel` conserva el estado del viaje, preferencias, alternativas, recomendación, selección y análisis de incidentes. Añade la intención temporal del viaje. El flujo es destino y origen resueltos, salida, cálculo OSRM existente, análisis de incidentes existente, contexto de decisión, resultado, presentación.

1. `CurrentMobilityDecisionAdapter` compone `MobilityDecisionContext` a partir del `MobilityContext`, `RouteOption`, análisis asociados por identificador y salida. No obtiene coordenadas de otra fuente ni consulta la red.
2. `MobilityDecisionCoordinator` envuelve la misma `MobilityRecommendation` del motor vehicular. Conserva su identidad, motivos y alternativas. No hace routing, scoring ni ranking.
3. `MobilityPlannerSection` presenta `MobilityDecisionResult`. El resumen y `RouteInsight` existentes siguen explicando la recomendación; el selector de alternativas mantiene la selección manual.

No se crea un segundo estado global ni se agregan APIs, paquetes, tablas o suscripciones. Las preferencias se cargan como antes; si no hay preferencias guardadas, se mantiene el fallback vehicular.

## Datos y modos

Driving usa los extremos resueltos y rutas vehiculares existentes del mismo viaje. Distancia y duración están disponibles solo cuando existe esa ruta. Los reportes viales se marcan disponibles solo con análisis asociado a todas las alternativas; ausencia de reportes no equivale a cero incidentes.

Walking, cycling y public transport se muestran como no soportados. No heredan geometría, tiempo ni distancia de una ruta de automóvil. Los modos excluidos por preferencias siguen identificados como excluidos.

## Salida

Ahora conserva el flujo vehicular actual. Programar permite seleccionar fecha y hora futuras y conserva la fecha al cerrar los selectores. No crea alertas, reservas ni persistencia fuera del flujo.

No hay evidencia temporal suficiente para ajustar una recomendación a una salida futura. La salida programada no inicia cálculos de ruta. Si ya existe una ruta calculada para Ahora, permanece como referencia explícita: se retiran la recomendación y la acción para iniciar navegación. Volver a Ahora recupera la recomendación actual sin otra llamada a OSRM. No se presenta el tiempo de proveedor como predicción futura.

## Presentación, realtime y continuidad

El mapa conserva protagonismo; el panel tiene ancho máximo de 560 px, desplazamiento interno y altura limitada. El formulario presenta destino/origen, salida, medios y resultado. Los otros medios se expanden bajo demanda. Los controles temporales usan `Wrap` y el estado combina icono y texto con color.

Los reportes realtime usan las suscripciones existentes. Un snapshot nuevo recalcula análisis y recomendación sin nueva suscripción ni llamada OSRM, y conserva geometría y selección manual. GPS, origen manual, búsqueda, alternativas, `RouteInsight` y navegación existente se mantienen.

La cobertura de widgets del planificador y del panel usa anchos 320, 390, 768 y 1440 px, con escala de texto 1.5x. También se prueban la selección de fecha, el rechazo de una hora pasada y los cambios entre Ahora y Programar.

## Guion manual

1. Iniciar sesión.
2. Abrir el mapa.
3. Obtener la ubicación GPS y comprobar que aparece el origen actual.
4. Buscar y seleccionar un destino.
5. Confirmar que la salida está en Ahora.
6. Expandir Otros medios y revisar Vehículo, A pie, Bicicleta y Transporte público.
7. Calcular la ruta vehicular.
8. Abrir las alternativas y comprobar sus métricas.
9. Revisar Ruta sugerida y sus motivos.
10. Abrir ¿Por qué esta ruta? y comprobar el análisis de incidentes.
11. Seleccionar otra alternativa y comprobar que la selección manual se conserva.
12. Elegir Programar salida.
13. Elegir y confirmar una fecha y hora futuras.
14. Comprobar el aviso de falta de datos temporales y que los minutos existentes se identifican como referencia de Ahora.
15. Volver a Ahora y comprobar que vuelve la recomendación sin una llamada nueva de routing.
16. Recibir o consultar reportes viales y comprobar que se actualiza el análisis sin cambiar la ruta seleccionada.
17. Iniciar navegación y comprobar el flujo de navegación existente.

## Límites y trabajo pendiente para OE3

Faltan fuentes temporales reales con cobertura y vigencia verificables, evaluación de horarios, y routing/proveedores apropiados para cada medio adicional. El adaptador declara capacidades conocidas; no certifica calidad de proveedores ni condiciones futuras. La precisión de direcciones sigue siendo una limitación existente. No se afirma que OE3 esté completo.
