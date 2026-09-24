# Variables de movilidad provisionales

> **BASE PROVISIONAL — EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124**
>
> Responsable: Brayan. Actualización B5: `feature/implementation-traceability-update`. Baseline auditado: `f2009b2de71a5a36a97b1b1e422a865aeaf93e8c` (2026-09-21).
> FDC-124 NO LOCALIZADO. No hay citas institucionales verificadas ni cumplimiento académico certificado. Las asociaciones a objetivos son propuestas revisables.

Disponibilidad técnica significa que existe una integración o representación en código; no confirma respuesta en vivo. Las variables potenciales no son obligaciones institucionales. Ver [matriz](traceability_matrix.md).

## VM-01 — Coordenadas actuales

- **Descripción:** Latitud/longitud obtenidas bajo permiso.
- **Clasificación/origen:** DERIVADO TÉCNICO; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE2, OE3.
- **Utilidad:** Usar origen actual.
- **Fuente requerida:** Geolocalización del dispositivo.
- **Fuente actual/evidencia:** [lib/services/location_service.dart](../../lib/services/location_service.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** Lectura puntual, sin evidencia de seguimiento continuo ni precisión medida.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-02 — Origen

- **Descripción:** Texto y coordenadas elegidas o geocodificadas.
- **Clasificación/origen:** DERIVADO FUNCIONAL; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE2, OE3.
- **Utilidad:** Entrada del recorrido.
- **Fuente requerida:** Usuario, GPS, Photon o Nominatim.
- **Fuente actual/evidencia:** [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** Edición invalida y cursor conserva selección en el alcance probado de RF-ROUTE-03; aún no se utiliza en recomendaciones personalizadas.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-03 — Destino

- **Descripción:** Texto y coordenadas de llegada.
- **Clasificación/origen:** DERIVADO FUNCIONAL; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE2, OE3.
- **Utilidad:** Entrada del recorrido.
- **Fuente requerida:** Usuario, Photon o Nominatim.
- **Fuente actual/evidencia:** [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** No expresa preferencias personales.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-04 — Nombre y contexto del lugar

- **Descripción:** Etiqueta y descripción de un resultado.
- **Clasificación/origen:** DERIVADO TÉCNICO; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE2, OE4.
- **Utilidad:** Distinguir lugares.
- **Fuente requerida:** Photon y Nominatim.
- **Fuente actual/evidencia:** [lib/models/place_suggestion.dart](../../lib/models/place_suggestion.dart); [lib/models/geocoding_result.dart](../../lib/models/geocoding_result.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** Cobertura/calidad reales no medidas.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-05 — Geometría

- **Descripción:** Secuencia de puntos del recorrido GeoJSON.
- **Clasificación/origen:** DERIVADO TÉCNICO; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE2, OE3.
- **Utilidad:** Dibujar y encuadrar ruta.
- **Fuente requerida:** OSRM routes[i].geometry; Home muestra la alternativa seleccionada.
- **Fuente actual/evidencia:** [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/models/route_result.dart](../../lib/models/route_result.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** No incluye navegación paso a paso: steps=false.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-06 — Distancia

- **Descripción:** Longitud calculada en metros.
- **Clasificación/origen:** DERIVADO TÉCNICO; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE3, OE4.
- **Utilidad:** Informar recorrido.
- **Fuente requerida:** OSRM routes[i].distance; metros por candidata.
- **Fuente actual/evidencia:** [lib/models/route_result.dart](../../lib/models/route_result.dart); [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** No es distancia recorrida medida ni ahorro.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-07 — Duración estimada

- **Descripción:** Tiempo modelado en segundos.
- **Clasificación/origen:** DERIVADO TÉCNICO; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE3, OE4.
- **Utilidad:** Informar estimación del recorrido.
- **Fuente requerida:** OSRM routes[i].duration; segundos estimados por candidata.
- **Fuente actual/evidencia:** [lib/models/route_result.dart](../../lib/models/route_result.dart); [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart)
- **Estado técnico:** IMPLEMENTADO.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE.
- **Brecha:** No demuestra tráfico en tiempo real, horario o puntualidad.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-08 — Modo de transporte

- **Descripción:** Modo para calcular/comparar desplazamientos.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE3.
- **Utilidad:** Comparación de medios provisional.
- **Fuente requerida:** Proveedor con modos aprobados.
- **Fuente actual/evidencia:** [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart)
- **Estado técnico:** PARCIAL.
- **Disponibilidad:** Cuatro modos definidos en [TransportMode](../../lib/mobility/transport_mode.dart) y seleccionables en [B3](../../lib/screens/preferences/mobility_preferences_screen.dart); routing disponible solo con driving fijo.
- **Brecha:** La selección local no cambia OSRM; faltan proveedores para otros modos, comparación multimodal e integración con recomendaciones.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-09 — Metadatos del catálogo

- **Descripción:** Nombre, origen, destino, descripción y activa.
- **Clasificación/origen:** DERIVADO FUNCIONAL; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE4.
- **Utilidad:** Consultar rutas registradas.
- **Fuente requerida:** Tabla rutas de Supabase.
- **Fuente actual/evidencia:** [lib/models/ruta_model.dart](../../lib/models/ruta_model.dart); [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart)
- **Estado técnico:** PARCIAL.
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE mediante integración.
- **Brecha:** Datos poblados no verificados; activa es estado del registro, no disponibilidad de buses.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-10 — Preferencias de movilidad

- **Descripción:** Criterios del usuario para personalizar.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE1, OE3.
- **Utilidad:** Definir personalización.
- **Fuente requerida:** Captura consentida y esquema por aprobar.
- **Fuente actual/evidencia:** [Pantalla B3](../../lib/screens/preferences/mobility_preferences_screen.dart), [acceso desde Perfil](../../lib/screens/perfil/perfil_screen.dart), [contrato de contexto](../../lib/mobility/mobility_context.dart); [pruebas](../../test/screens/preferences/mobility_preferences_screen_test.dart) y [descarte al salir](../../test/perfil/perfil_screen_test.dart).
- **Estado técnico:** PARCIAL.
- **Disponibilidad:** CAPTURADA EN UI: selección de modos no vacía al confirmar, entregada como conjunto inmutable a callback opcional; el acceso desde Perfil no conecta un consumidor.
- **Brecha:** Se pierde al salir de la pantalla, sin persistencia local/remota ni procesamiento para personalizar. Perfil Supabase mantiene solo identidad, rol y activo. No hay pesos o prioridades de tiempo/distancia capturados.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-11 — Horarios

- **Descripción:** Ventanas de salida o servicio según alcance.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE1, OE3.
- **Utilidad:** Comparación temporal provisional.
- **Fuente requerida:** Fuente de operadores o captura aprobada.
- **Fuente actual/evidencia:** [lib/models/ruta_model.dart](../../lib/models/ruta_model.dart) La ruta citada, cuando existe, evidencia la limitación; no una fuente disponible.
- **Estado técnico:** PENDIENTE.
- **Disponibilidad:** PENDIENTE DE FUENTE REAL.
- **Brecha:** No hay horarios en el modelo de catálogo; alcance no verificado.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-12 — Alternativas y puntuación

- **Descripción:** Candidatas y criterio explicable de comparación.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE3.
- **Utilidad:** Ordenar recomendaciones.
- **Fuente requerida:** Modelo, objetivos y fuentes aprobados.
- **Fuente actual/evidencia:** [OSRM](../../lib/services/osrm_routing_service.dart), [panel](../../lib/widgets/map_search_panel.dart), [selector](../../lib/widgets/route_alternatives_selector.dart), [RouteOption](../../lib/mobility/route_option.dart); [pruebas de servicio](../../test/services/osrm_routing_service_test.dart) y [flujo](../../test/screens/home/route_flow_test.dart).
- **Estado técnico:** PARCIAL.
- **Disponibilidad:** Alternativas vehiculares obtenidas con `alternatives=true`, validadas y seleccionables manualmente; puede haber solo una. Contratos de razones y recomendación definidos.
- **Brecha:** Puntuación, ranking y evaluación personalizada pendientes. Home conserva `RouteResult`, no genera `MobilityRecommendation`; el orden del proveedor no es scoring propio.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-13 — Condiciones de circulación

- **Descripción:** Tráfico/congestión/incidentes como candidatos.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE1, OE3.
- **Utilidad:** Evaluar si aportan a recomendaciones.
- **Fuente requerida:** Fuente real y licencia por identificar.
- **Fuente actual/evidencia:** [MobilityConditions](../../lib/mobility/mobility_conditions.dart) y [pruebas de dominio](../../test/mobility/mobility_domain_test.dart) evidencian representación conceptual, no fuente de datos reales.
- **Estado técnico:** NO VERIFICADO.
- **Disponibilidad:** PENDIENTE DE FUENTE REAL.
- **Brecha:** Congestión, incidentes y retraso son campos opcionales; `null` significa desconocido, no cero. Sin proveedor, captura ni procesamiento productivo. Necesidad institucional por definir; se conserva NO VERIFICADO por esa incertidumbre.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-14 — Oferta de transporte

- **Descripción:** Buses y disponibilidad como candidatos.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE1, OE3.
- **Utilidad:** Evaluar opciones de viaje.
- **Fuente requerida:** Operadores y datos verificables por definir.
- **Fuente actual/evidencia:** No identificada. La ruta citada, cuando existe, evidencia la limitación; no una fuente disponible.
- **Estado técnico:** NO VERIFICADO.
- **Disponibilidad:** PENDIENTE DE FUENTE REAL.
- **Brecha:** Catálogo no prueba oferta operativa. No afirmar buses disponibles.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## Límites del inventario

Clima, ahorro y reportes ciudadanos no tienen fuente ni necesidad institucional demostradas; no se incorporan como requisitos confirmados ni datos disponibles. Un contraste futuro con FDC deberá justificar cualquier ampliación; B5 conserva todos los identificadores. Una recomendación es una salida de un motor pendiente, no un dato real aportado por OSRM.

## Captura, uso y procesamiento actuales

Esta tabla complementa los estados anteriores. «Sí» describe integración de código, no una consulta en vivo durante B5. Ninguna variable está integrada en un motor productivo de recomendaciones.

| Variable existente | Definición | Captura actual | Uso actual | Proveedor / procesamiento pendiente |
| --- | --- | --- | --- | --- |
| VM-01 | Coordenadas | Geolocator bajo permiso | Origen Home y marcador | Precisión/dispositivo por validar; personalización pendiente |
| VM-02 | Origen | GPS, texto, Photon/Nominatim; tap en Rutas | Petición OSRM en Home; punto en Rutas | Integración con motor pendiente |
| VM-03 | Destino | Texto, Photon/Nominatim; tap en Rutas | Petición OSRM en Home; punto en Rutas | Integración con motor pendiente |
| VM-04 | Nombre/contexto | Photon/Nominatim | Selección y etiquetas | Calidad geográfica por validar; no es fuente Nearby |
| VM-05 | Geometría | OSRM por candidata | Polyline y encuadre de selección | Sin navegación paso a paso ni análisis personalizado |
| VM-06 | Distancia | OSRM por candidata | Comparación visual, tarjeta y detalles | Scoring propio pendiente |
| VM-07 | Duración estimada | OSRM por candidata | Comparación visual, tarjeta y detalles | No tráfico observado; scoring propio pendiente |
| VM-08 | Cuatro modos conceptuales | Selección B3 local | Estado de UI; OSRM sigue driving | Otros proveedores y comparación multimodal pendientes |
| VM-09 | Registro de catálogo | Integración Supabase | Listado/filtro y administración | Datos/políticas remotas por verificar; no oferta operativa |
| VM-10 | Preferencias: modos | B3 local, sin persistencia | Confirmar/deshacer; callback sin consumidor desde Perfil | Persistencia e integración con viaje/motor pendientes |
| VM-11 | Horarios conceptuales | No | Ninguno | Fuente, modelo operativo y procesamiento pendientes |
| VM-12 | Candidatas y puntuación | Candidatas OSRM; sin puntuación propia | Selección manual, sin otra consulta | Ranking, razones calculadas y evaluación pendientes |
| VM-13 | Condiciones opcionales en dominio | No | Validación de valores en modelos/tests | Alcance por definir; proveedor y procesamiento pendientes |
| VM-14 | Oferta conceptual | No | Ninguno | Alcance, operadores y datos pendientes |
