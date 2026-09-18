# Requisitos no funcionales provisionales

> **BASE PROVISIONAL — EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124**
>
> Responsable: Brayan. Rama: `feature/fdc-requirements-baseline`. Baseline auditado: `e1883e255bc6f00ae1f34a065dcde9623406e0e9`.
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
- **Brecha:** Nominatim no impone timeout propio; cobertura depende del llamador. Sin medición de latencia real.
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
- **Brecha:** Resumen probado a 390, 768 y 1440 px; no equivale a auditoría responsive global.
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
- **Brecha:** Semántica parcial; faltan usuarios, lector de pantalla, teclado y contraste.
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
- **Brecha:** Existe legado Google y duplicación Home/Rutas; no se acredita cobertura total.
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
- **Estado técnico:** NO VERIFICADO.
- **Evidencia de código:** [pubspec.yaml](../../pubspec.yaml); [README.md](../../README.md).
- **Prueba/evidencia:** [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart)
- **Brecha:** Tamaños de widget no prueban compilación ni funcionamiento nativo; matriz objetivo pendiente.
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
- **Brecha:** Endpoint configurable; capacidad, disponibilidad y operación productiva no verificadas.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.
