# Requisitos no funcionales provisionales

> **BASE PROVISIONAL — EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124**
>
> Responsable: Brayan. Actualización B5: `feature/implementation-traceability-update`. Baseline auditado: `f2009b2de71a5a36a97b1b1e422a865aeaf93e8c` (2026-09-21).
> FDC-124 NO LOCALIZADO. No hay citas institucionales verificadas ni cumplimiento académico certificado. Las asociaciones a objetivos son propuestas revisables.

Origen técnico o UX; no constituyen mandatos institucionales. Para todos los RNF: **criterio cuantitativo pendiente de FDC/validación académica**. No se establecen SLA ni umbrales nuevos. Los tamaños y temporizadores citados describen pruebas o implementación existentes.

## RNF-PERF-01 — Control de consultas

- **Descripción verificable:** Aplicar debounce y descartar respuestas obsoletas por campo.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Control asíncrono.
- **Objetivo provisional:** OE2.
- **Módulo:** Búsqueda.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart); [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart).
- **Prueba/evidencia:** [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart)
- **Brecha:** Los temporizadores observados son decisiones técnicas, no SLA.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-PERF-02 — Espera acotada

- **Descripción verificable:** Terminar esperas de búsqueda/cálculo con error comprensible.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Timeouts existentes.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Servicios.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/services/geocoding_service.dart](../../lib/services/geocoding_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/services/place_suggestion_service_test.dart](../../test/services/place_suggestion_service_test.dart)
- **Brecha:** Photon limita a 8 s en servicio y 10 s en UI; OSRM a 15 s en servicio y 20 s en Home. Nominatim no impone timeout propio: Home envuelve cada búsqueda en 10 s, pero RutasScreen llama sin timeout. No hay medición de latencia real ni SLA; los límites por etapa no son un límite total del viaje.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-SEC-01 — Autorización efectiva

- **Descripción verificable:** Restringir operaciones administrativas en servidor y no solo en interfaz.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Datos y roles Supabase.
- **Objetivo provisional:** OE2.
- **Módulo:** Seguridad.
- **Estado técnico:** NO VERIFICADO.
- **Evidencia de código:** [lib/services/perfil_service.dart](../../lib/services/perfil_service.dart); [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart).
- **Prueba/evidencia:** Sin prueba dedicada identificada.
- **Brecha:** No se localizaron políticas SQL/RLS ni implementación de crear-usuario; verificar backend.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-SEC-02 — Privacidad de ubicación

- **Descripción verificable:** Solicitar permisos y mantener alternativa manual; definir tratamiento de datos enviados a proveedores.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Geolocalización y peticiones externas.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Privacidad.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/services/location_service.dart](../../lib/services/location_service.dart); [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [README.md](../../README.md).
- **Prueba/evidencia:** [test/services/location_service_test.dart](../../test/services/location_service_test.dart)
- **Brecha:** Permisos implementados; política de retención/consentimiento y tratamiento remoto no verificada.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-USA-01 — Interfaz adaptable

- **Descripción verificable:** Conservar legibilidad y acciones en paneles flotantes y resumen sin desbordamiento.
- **Clasificación:** UX.
- **Origen:** Diseño A.
- **Objetivo provisional:** OE4.
- **Módulo:** Interfaz.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart); [lib/main.dart](../../lib/main.dart).
- **Prueba/evidencia:** [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart)
- **Pruebas adicionales:** [Flujo Home](../../test/screens/home/route_flow_test.dart), [selector](../../test/widgets/route_alternatives_selector_test.dart), [preferencias](../../test/screens/preferences/mobility_preferences_screen_test.dart) y [Nearby](../../test/screens/nearby/nearby_places_screen_test.dart).
- **Brecha:** Home/selector/tarjeta y preferencias tienen pruebas a 320, 390, 768 y 1440 px con texto al 150 %; no equivale a auditoría responsive global.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-USA-02 — Accesibilidad y comprensión

- **Descripción verificable:** Ofrecer etiquetas comprensibles, semántica y mensajes de error utilizables.
- **Clasificación:** UX.
- **Origen:** Diseño A y controles actuales.
- **Objetivo provisional:** OE4.
- **Módulo:** Interfaz.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/widgets/route_map.dart](../../lib/widgets/route_map.dart); [lib/widgets/route_planner_form.dart](../../lib/widgets/route_planner_form.dart).
- **Prueba/evidencia:** [test/widgets/route_map_test.dart](../../test/widgets/route_map_test.dart); [test/widgets/route_planner_form_test.dart](../../test/widgets/route_planner_form_test.dart)
- **Evidencia adicional:** [Selector](../../lib/widgets/route_alternatives_selector.dart) con texto, icono y semántica de selección; [pruebas](../../test/widgets/route_alternatives_selector_test.dart). Preferencias y Nearby comunican sus límites en la UI.
- **Brecha:** Semántica local probada; faltan evaluación con usuarios, lector de pantalla, teclado y contraste en ejecución real.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-MAINT-01 — Separación y verificabilidad

- **Descripción verificable:** Separar modelos/servicios/UI y permitir dobles de servicios para regresiones.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Arquitectura observable.
- **Objetivo provisional:** OE2.
- **Módulo:** Arquitectura.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/models/route_result.dart](../../lib/models/route_result.dart); [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart)
- **Evidencia adicional:** [Dominio neutral](../mobility-domain.md), [contrato](../../lib/mobility/mobility_recommendation_engine.dart) y [pruebas de dominio](../../test/mobility/mobility_domain_test.dart). La interfaz del motor permite un doble, pero no hay estrategia productiva.
- **Brecha:** Existe legado Google y duplicación Home/Rutas; no se acredita cobertura total ni integración productiva del dominio con recomendaciones.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-MAINT-02 — Integridad de datos externos

- **Descripción verificable:** Rechazar coordenadas inválidas, geometría vacía y métricas no finitas o negativas.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Validadores de servicios.
- **Objetivo provisional:** OE2, OE3.
- **Módulo:** Calidad.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/services/geocoding_service.dart](../../lib/services/geocoding_service.dart); [lib/services/place_suggestion_service.dart](../../lib/services/place_suggestion_service.dart).
- **Prueba/evidencia:** [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/services/geocoding_service_test.dart](../../test/services/geocoding_service_test.dart); [test/services/place_suggestion_service_test.dart](../../test/services/place_suggestion_service_test.dart)
- **Brecha:** Validación estructural no demuestra exactitud geográfica.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-COMP-01 — Compatibilidad

- **Descripción verificable:** Verificar flujo y permisos en plataformas objetivo que se aprueben.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Flutter y directorios de plataforma.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Plataformas.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [pubspec.yaml](../../pubspec.yaml); [README.md](../../README.md).
- **Prueba/evidencia:** [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart); [registro de compilación web de B4](../route-alternatives.md).
- **Brecha:** B4 registra compilación web correcta; B5 no la repite. No acredita flujo OAuth/permisos en navegador real ni ejecución nativa; plataformas objetivo y matriz de aceptación pendientes.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RNF-MAINT-03 — Operación de proveedores

- **Descripción verificable:** Definir configuración y validación operativa de servicios externos para despliegue.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Endpoint de demostración.
- **Objetivo provisional:** OE2.
- **Módulo:** Operación.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/config/osrm_config.dart](../../lib/config/osrm_config.dart); [README.md](../../README.md).
- **Prueba/evidencia:** [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart)
- **Brecha:** OSRM usa endpoint público de demostración, sustituible mediante configuración/inyección; RouteMap usa tiles públicos OSM. Capacidad, disponibilidad y operación productiva no verificadas; definir infraestructura antes del despliegue estable.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.
