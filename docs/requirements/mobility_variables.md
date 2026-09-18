# Variables de movilidad provisionales

> **BASE PROVISIONAL — EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124**
>
> Responsable: Brayan. Rama: `feature/fdc-requirements-baseline`. Baseline auditado: `e1883e255bc6f00ae1f34a065dcde9623406e0e9`.
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
- **Brecha:** Integridad ante selección/cursor parcial: RF-ROUTE-03.
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
- **Fuente requerida:** OSRM routes.first.geometry.
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
- **Fuente requerida:** OSRM routes.first.distance.
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
- **Fuente requerida:** OSRM routes.first.duration.
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
- **Disponibilidad:** DISPONIBLE TÉCNICAMENTE solo driving fijo.
- **Brecha:** No hay selección ni comparación multimodal; fuentes adicionales pendientes.
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
- **Fuente actual/evidencia:** [lib/models/perfil_model.dart](../../lib/models/perfil_model.dart) La ruta citada, cuando existe, evidencia la limitación; no una fuente disponible.
- **Estado técnico:** PENDIENTE.
- **Disponibilidad:** PENDIENTE DE FUENTE REAL.
- **Brecha:** Perfil actual solo contiene identidad, rol y activo; no preferencias de viaje.
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
- **Fuente actual/evidencia:** [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart) La ruta citada, cuando existe, evidencia la limitación; no una fuente disponible.
- **Estado técnico:** PENDIENTE.
- **Disponibilidad:** PENDIENTE DE FUENTE REAL.
- **Brecha:** alternatives=false; no ranking ni evaluación de recomendaciones.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## VM-13 — Condiciones de circulación

- **Descripción:** Tráfico/congestión/incidentes como candidatos.
- **Clasificación/origen:** PENDIENTE DE VERIFICACIÓN FDC-124; auditoría técnica o referencia provisional del coordinador.
- **Objetivo provisional:** OE1, OE3.
- **Utilidad:** Evaluar si aportan a recomendaciones.
- **Fuente requerida:** Fuente real y licencia por identificar.
- **Fuente actual/evidencia:** No identificada. La ruta citada, cuando existe, evidencia la limitación; no una fuente disponible.
- **Estado técnico:** NO VERIFICADO.
- **Disponibilidad:** PENDIENTE DE FUENTE REAL.
- **Brecha:** Ni necesidad institucional ni disponibilidad demostradas; no se exigen como alcance confirmado.
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

Clima, ahorro y reportes ciudadanos no tienen fuente ni necesidad institucional demostradas; no se incorporan como requisitos confirmados ni datos disponibles. Si el FDC los exige, crear IDs nuevos sin renumerar los existentes. Una recomendación es una salida de un modelo pendiente, no un dato real aportado por OSRM.
