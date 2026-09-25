# Requisitos funcionales provisionales

> **BASE PROVISIONAL — EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124**
>
> Responsable actual: Sebastián. Incremento: `feature/demo-flow-recovery-and-evidence`. Baseline: `189cd0a1a208b45f03a05f104ab61716db7ee38a` (PR #33 integrado, 206 pruebas; 2026-09-25).
> FDC-124 NO LOCALIZADO. No hay citas institucionales verificadas ni cumplimiento académico certificado. Las asociaciones a objetivos son propuestas revisables.

Los objetivos y las reglas de evidencia están definidos en [la matriz](traceability_matrix.md). IMPLEMENTADO significa capacidad observada en código y pruebas locales; no certifica operación remota ni cumplimiento del FDC. PARCIAL distingue capacidades incompletas o integraciones cuya verificación integral falta.

## RF-AUTH-01 — Acceso con credenciales

- **Descripción verificable:** Validar correo y contraseña y gestionar sesión mediante Supabase.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Código de acceso.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Autenticación.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/screens/login/login_screen.dart](../../lib/screens/login/login_screen.dart).
- **Prueba/evidencia:** [test/widget_test.dart](../../test/widget_test.dart)
- **Brecha:** Prueba de pantalla; falta ensayo integral con Supabase real.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-AUTH-02 — Acceso Google

- **Descripción verificable:** Iniciar OAuth Google y gestionar respuesta o error.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Código OAuth.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Autenticación.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/services/google_auth_service.dart](../../lib/services/google_auth_service.dart).
- **Prueba/evidencia:** [test/services/google_auth_service_test.dart](../../test/services/google_auth_service_test.dart)
- **Brecha:** El doble OAuth no valida proveedor, redirects ni despliegue.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-AUTH-03 — Control de sesión y cuenta

- **Descripción verificable:** Rechazar perfil inactivo y permitir cerrar sesión.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Login y Home.
- **Objetivo provisional:** OE2.
- **Módulo:** Autenticación.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/screens/login/login_screen.dart](../../lib/screens/login/login_screen.dart); [lib/screens/home/home_screen.dart](../../lib/screens/home/home_screen.dart).
- **Prueba/evidencia:** Sin prueba dedicada identificada.
- **Brecha:** Falta prueba integral de cuenta inactiva y cierre.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-PROFILE-01 — Perfil de usuario

- **Descripción verificable:** Obtener o crear perfil de sesión y mostrar nombre, correo, rol y estado.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Modelo y servicio de perfiles.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Perfil.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/services/perfil_service.dart](../../lib/services/perfil_service.dart); [lib/screens/perfil/perfil_screen.dart](../../lib/screens/perfil/perfil_screen.dart).
- **Prueba/evidencia:** [test/perfil/perfil_screen_test.dart](../../test/perfil/perfil_screen_test.dart); [recuperación Home](../../test/screens/home/home_screen_test.dart)
- **Brecha:** Visualización y recuperación local de Home probadas: fallo/null informados, reintento sin duplicar solicitudes ni SnackBars, mapa disponible y navegación tras recuperar. Persistencia y políticas remotas no verificadas.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-PROFILE-02 — Administrar usuarios

- **Descripción verificable:** Permitir crear usuarios, cambiar rol y estado desde administración.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Administración existente.
- **Objetivo provisional:** OE2.
- **Módulo:** Administración.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/screens/admin/usuarios/usuarios_screen.dart](../../lib/screens/admin/usuarios/usuarios_screen.dart); [lib/services/perfil_service.dart](../../lib/services/perfil_service.dart).
- **Prueba/evidencia:** Sin prueba dedicada identificada.
- **Brecha:** La función remota crear-usuario y autorización del servidor no están verificadas.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MAP-01 — Mapa base

- **Descripción verificable:** Mostrar mapa OpenStreetMap, atribución y marcadores mediante flutter_map.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Implementación cartográfica.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Mapa.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/widgets/route_map.dart](../../lib/widgets/route_map.dart).
- **Prueba/evidencia:** [test/widgets/route_map_test.dart](../../test/widgets/route_map_test.dart)
- **Brecha:** Integración local probada; disponibilidad de tiles no certificada.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MAP-02 — Ubicación actual

- **Descripción verificable:** Solicitar permiso, obtener coordenadas y ofrecer origen manual si falla.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Servicio y flujo Home.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Geolocalización.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/services/location_service.dart](../../lib/services/location_service.dart); [lib/screens/home/home_screen.dart](../../lib/screens/home/home_screen.dart).
- **Prueba/evidencia:** [test/services/location_service_test.dart](../../test/services/location_service_test.dart); [test/screens/home/home_screen_test.dart](../../test/screens/home/home_screen_test.dart)
- **Brecha:** Gateway simulado; permisos y precisión requieren prueba en dispositivo.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MAP-03 — Sugerencias de lugares

- **Descripción verificable:** Consultar Photon por campo y seleccionar nombre y coordenadas.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Servicio Photon y formularios.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Búsqueda.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/services/place_suggestion_service.dart](../../lib/services/place_suggestion_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/services/place_suggestion_service_test.dart](../../test/services/place_suggestion_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart)
- **Brecha:** Pruebas con respuestas simuladas; cobertura geográfica real no verificada.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MAP-04 — Geocodificación explícita

- **Descripción verificable:** Resolver texto sin selección con Nominatim al calcular; gestionar ausencia de resultado.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Fallback implementado.
- **Objetivo provisional:** OE2, OE3.
- **Módulo:** Geocodificación.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/services/geocoding_service.dart](../../lib/services/geocoding_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/services/geocoding_service_test.dart](../../test/services/geocoding_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart)
- **Brecha:** Consulta limitada a Colombia; no es motor de recomendaciones.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MAP-05 — Selección por mapa

- **Descripción verificable:** Permitir seleccionar origen/destino por tap y reiniciar en RutasScreen.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Pantalla Rutas.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Selección.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart).
- **Prueba/evidencia:** [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart)
- **Brecha:** Capacidad de RutasScreen; no implica cálculo OSRM en esa pantalla.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-ROUTE-01 — Ruta vehicular

- **Descripción verificable:** Con origen/destino válidos, solicitar una ruta driving a OSRM y mostrar error si no existe.
- **Clasificación:** DERIVADO TÉCNICO.
- **Origen:** Flujo Home OSRM.
- **Objetivo provisional:** OE2, OE3.
- **Módulo:** Planificación.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart)
- **Evidencia integrada:** Home consulta `routeAlternatives` con `alternatives=true` y conserva todas las candidatas en orden del proveedor. [Selector](../../lib/widgets/route_alternatives_selector.dart), [prueba del selector](../../test/widgets/route_alternatives_selector_test.dart) y [B4](../route-alternatives.md) verifican selección manual sin otra consulta. `route()` conserva su contrato de una ruta.
- **Brecha:** OSRM puede devolver una sola ruta; solo driving. #33 incorpora sugerencia inicial explicable mediante regla técnica provisional, sin personalización completa ni garantía de ruta óptima.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-ROUTE-02 — Geometría y métricas

- **Descripción verificable:** Mostrar geometría completa, distancia y duración estimada del resultado; encuadrar recorrido.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Resultado OSRM.
- **Objetivo provisional:** OE3, OE4.
- **Módulo:** Resultados.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/models/route_result.dart](../../lib/models/route_result.dart); [lib/widgets/route_map.dart](../../lib/widgets/route_map.dart); [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart).
- **Prueba/evidencia:** [test/widgets/route_map_test.dart](../../test/widgets/route_map_test.dart); [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart)
- **Evidencia integrada:** La alternativa seleccionada sincroniza geometría, distancia, duración y detalles en Home sin nueva consulta; se dibuja un recorrido a la vez.
- **Brecha:** Duración estimada por OSRM, no tráfico observado ni hora de llegada garantizada. No son mediciones de un viaje realizado.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-ROUTE-03 — Integridad del estado

- **Descripción verificable:** Invalidar cálculo ante cambio real de entrada y conservar selección y resultado ante cambios solo de cursor.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Coherencia del planificador.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Estado de ruta.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart); [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart).
- **Prueba/evidencia:** [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart); [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart)
- **Evidencia integrada:** Los listeners comparan texto. Home conserva resultados ante cursor/selección/composición sin edición; una edición, cambio de origen manual/GPS o coordenadas GPS limpia alternativas. Identificador de cálculo y `mounted` descartan respuestas obsoletas y posteriores al desmontaje. Las regresiones citadas están en este baseline.
- **Brecha:** Evidencia local de los flujos probados; RutasScreen conserva selección de puntos, pero no calcula rutas OSRM.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-ROUTE-04 — Carga y errores

- **Descripción verificable:** Impedir cálculo duplicado mientras carga y retirar resultado ante error; permitir reintento.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Flujo asíncrono.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Planificación.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart)
- **Brecha:** No garantiza disponibilidad del proveedor.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-ROUTE-05 — Consultar catálogo

- **Descripción verificable:** Cargar rutas activas de Supabase y filtrarlas por texto.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Catálogo existente.
- **Objetivo provisional:** OE4.
- **Módulo:** Catálogo.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart); [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart).
- **Prueba/evidencia:** [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart)
- **Brecha:** Filtro local probado por nombre, origen, destino y descripción, sin distinguir mayúsculas, con trim, vacío, sin coincidencias y recarga que conserva consulta. Catálogo inyectado: faltan datos, políticas y ensayo integral de Supabase real; por eso sigue PARCIAL.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-ROUTE-06 — Administrar catálogo

- **Descripción verificable:** Crear y editar rutas y cambiar su estado, validando campos obligatorios.
- **Clasificación:** DERIVADO FUNCIONAL.
- **Origen:** Administración existente.
- **Objetivo provisional:** OE2, OE4.
- **Módulo:** Catálogo.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart); [lib/screens/admin/rutas/rutas_admin_screen.dart](../../lib/screens/admin/rutas/rutas_admin_screen.dart).
- **Prueba/evidencia:** Sin prueba dedicada identificada.
- **Brecha:** Sin pruebas dedicadas de persistencia/autorización; activa no significa servicio disponible.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-UI-01 — Navegación principal

- **Descripción verificable:** Acceder desde Drawer a mapa, rutas y perfil; mostrar administración según rol.
- **Clasificación:** UX.
- **Origen:** Diseño A y navegación existente.
- **Objetivo provisional:** OE4.
- **Módulo:** Navegación.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/widgets/app_navigation_drawer.dart](../../lib/widgets/app_navigation_drawer.dart); [lib/screens/home/home_screen.dart](../../lib/screens/home/home_screen.dart).
- **Prueba/evidencia:** [test/screens/home/home_screen_test.dart](../../test/screens/home/home_screen_test.dart)
- **Brecha:** Prueba parcial de navegación; ocultar menú no demuestra seguridad del backend.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-UI-02 — Resultado progresivo

- **Descripción verificable:** Presentar resumen compacto, detalles y acción para modificar la ruta sobre el mapa.
- **Clasificación:** UX.
- **Origen:** Diseño A y tarjetas actuales.
- **Objetivo provisional:** OE4.
- **Módulo:** Interfaz.
- **Estado técnico:** IMPLEMENTADO.
- **Evidencia de código:** [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart).
- **Prueba/evidencia:** [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart); [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart)
- **Evidencia integrada:** Título neutral «Ruta seleccionada», detalles de la candidata vigente y [selector de alternativas](../../lib/widgets/route_alternatives_selector.dart), probado en [test/widgets/route_alternatives_selector_test.dart](../../test/widgets/route_alternatives_selector_test.dart).
- **Brecha:** Comprensión por público general pendiente de evaluación con usuarios; elegir manualmente no equivale a recomendación personalizada.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MOB-01 — Recomendación personalizada

- **Descripción verificable:** Producir recomendación explicable a partir de variables y preferencias definidas y comparar alternativas.
- **Clasificación:** PENDIENTE DE VERIFICACIÓN FDC-124.
- **Origen:** OE3 suministrado por coordinador.
- **Objetivo provisional:** OE3.
- **Módulo:** Recomendaciones.
- **Estado técnico:** PARCIAL.
- **Evidencia de código:** [Motor vehicular](../../lib/mobility/vehicle_recommendation_engine.dart), [panel integrado](../../lib/widgets/map_search_panel.dart), [resumen explicable](../../lib/widgets/mobility_recommendation_summary.dart), [persistencia local](../../lib/services/mobility_preferences_service.dart).
- **Prueba/evidencia:** [Motor](../../test/mobility/vehicle_recommendation_engine_test.dart), [resumen](../../test/widgets/mobility_recommendation_summary_test.dart), [flujo Home](../../test/screens/home/route_flow_test.dart), [servicio de preferencias](../../test/services/mobility_preferences_service_test.dart).
- **Evidencia integrada:** #31 persiste modos por instalación; #32 compara mínimos/diferencias; #33 produce una recomendación vehicular explicable sobre candidatas OSRM elegibles: menor duración estimada → menor distancia → orden del proveedor. Es una regla técnica provisional, no IA ni requisito institucional. Sin modos guardados se comunica el flujo driving por defecto, sin atribuirlo al usuario. Con driving se evalúan candidatas; con modos guardados sin driving no se selecciona una ruta vehicular ni se simulan otros modos. Un fallo de lectura no equivale a ausencia de preferencias. «Ruta sugerida» distingue la decisión inicial de «Selección manual», sin nuevas consultas y con mapa/tarjeta/detalles sincronizados.
- **Brecha:** Existe motor productivo, pero solo vehicular. La preferencia de modo decide elegibilidad; no hay prioridades personales de tiempo/distancia, personalización completa, preferencias por cuenta, sincronización Supabase ni evaluación con usuarios. No se garantiza ruta óptima ni se usan tráfico, congestión o incidentes en tiempo real. Faltan fuentes/comparación entre medios y horarios (RF-MOB-02), y contraste de criterios con FDC. Por ello RF-MOB-01 es PARCIAL, no PENDIENTE ni cumplimiento académico definitivo.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.

## RF-MOB-02 — Horarios y modos

- **Descripción verificable:** Consultar y comparar horarios y medios cuando se apruebe alcance y existan fuentes reales.
- **Clasificación:** PENDIENTE DE VERIFICACIÓN FDC-124.
- **Origen:** OE3 provisional.
- **Objetivo provisional:** OE1, OE3, OE4.
- **Módulo:** Información de movilidad.
- **Estado técnico:** PENDIENTE.
- **Evidencia de código:** [lib/models/ruta_model.dart](../../lib/models/ruta_model.dart); [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart).
- **Prueba/evidencia:** Sin prueba dedicada identificada.
- **Evidencia integrada:** [TransportMode](../../lib/mobility/transport_mode.dart) representa cuatro modos y [B3](../mobility-preferences.md) permite guardarlos por instalación; #33 usa driving para elegibilidad, sin cambiar el perfil fijo de OSRM ni calcular otros medios.
- **Brecha:** Catálogo sin horarios; OSRM usa driving fijo. Consulta y comparación real entre horarios/modos permanecen PENDIENTES; faltan fuentes y procesamiento.
- **Verificación FDC:** PENDIENTE DE VERIFICACIÓN FDC-124.
