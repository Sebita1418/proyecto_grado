# Matriz provisional de trazabilidad

> **BASE PROVISIONAL — EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124**
>
> Responsable: Brayan. Rama: `feature/fdc-requirements-baseline`. Baseline auditado: `e1883e255bc6f00ae1f34a065dcde9623406e0e9`.
> FDC-124 NO LOCALIZADO. No hay citas institucionales verificadas ni cumplimiento académico certificado. Las asociaciones a objetivos son propuestas revisables.

## Referencias y autoridad

**REFERENCIA PROVISIONAL DEL PROYECTO — PENDIENTE DE VERIFICACIÓN FDC-124.** Los siguientes objetivos proceden del coordinador y no son citas institucionales:

| Objetivo | Referencia provisional |
| --- | --- |
| OE1 | Analizar requerimientos funcionales y no funcionales, necesidades de usuarios y variables relevantes de movilidad. |
| OE2 | Diseñar arquitectura que integre geolocalización, procesamiento/análisis y visualización. |
| OE3 | Construir un modelo de procesamiento y análisis de información de movilidad para recomendaciones personalizadas de rutas, horarios y medios. |
| OE4 | Desarrollar interfaz intuitiva para consultar movilidad y recomendaciones que apoyen decisiones. |

Objetivo general, alcance, restricciones, redacción exacta de OE y criterios institucionales: **PENDIENTE DE VERIFICACIÓN FDC-124**. No se reconstruye un objetivo general a partir del código.

Fuentes técnicas: [README](../../README.md), [baseline OSM histórico](../osm-baseline.md), código y tests enlazados. El documento OSM describe una etapa anterior sin routing; no prevalece sobre el código e1883e2 que sí implementa OSRM en Home. Diseño A es referencia UX del coordinador, no fuente institucional. Flutter, Supabase, OSRM, Photon, Nominatim, OpenStreetMap y flutter_map son decisiones técnicas.

## Interpretación de estados

- IMPLEMENTADO: capacidad técnica presente con evidencia local; no certifica servicio remoto ni cumplimiento académico.
- PARCIAL: solo parte de la capacidad o validación integral está disponible.
- PENDIENTE: capacidad provisional propuesta sin implementación identificada.
- NO VERIFICADO: evidencia insuficiente para afirmar necesidad o cumplimiento.
- NO APLICA: reservado para exclusión justificada; no utilizado para ocultar brechas.

Todos los vínculos institucionales están pendientes. El estado técnico y la verificación académica son columnas independientes. Las pruebas usan dobles y datos de prueba; estos no representan datos de movilidad reales.

## Requisitos y evidencia

| Objetivo provisional | Requisito | Módulo | Implementación o evidencia de límite | Prueba | Estado | Brecha | Verificación FDC / referencia institucional |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OE2, OE4 | [RF-AUTH-01](functional_requirements.md) | Autenticación | [lib/screens/login/login_screen.dart](../../lib/screens/login/login_screen.dart) | [test/widget_test.dart](../../test/widget_test.dart) | PARCIAL | Prueba de pantalla; falta ensayo integral con Supabase real. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-AUTH-02](functional_requirements.md) | Autenticación | [lib/services/google_auth_service.dart](../../lib/services/google_auth_service.dart) | [test/services/google_auth_service_test.dart](../../test/services/google_auth_service_test.dart) | PARCIAL | El doble OAuth no valida proveedor, redirects ni despliegue. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2 | [RF-AUTH-03](functional_requirements.md) | Autenticación | [lib/screens/login/login_screen.dart](../../lib/screens/login/login_screen.dart); [lib/screens/home/home_screen.dart](../../lib/screens/home/home_screen.dart) | No identificada. | PARCIAL | Falta prueba integral de cuenta inactiva y cierre. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-PROFILE-01](functional_requirements.md) | Perfil | [lib/services/perfil_service.dart](../../lib/services/perfil_service.dart); [lib/screens/perfil/perfil_screen.dart](../../lib/screens/perfil/perfil_screen.dart) | [test/perfil/perfil_screen_test.dart](../../test/perfil/perfil_screen_test.dart) | PARCIAL | Visualización probada; persistencia y políticas remotas no verificadas. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2 | [RF-PROFILE-02](functional_requirements.md) | Administración | [lib/screens/admin/usuarios/usuarios_screen.dart](../../lib/screens/admin/usuarios/usuarios_screen.dart); [lib/services/perfil_service.dart](../../lib/services/perfil_service.dart) | No identificada. | PARCIAL | La función remota crear-usuario y autorización del servidor no están verificadas. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-MAP-01](functional_requirements.md) | Mapa | [lib/widgets/route_map.dart](../../lib/widgets/route_map.dart) | [test/widgets/route_map_test.dart](../../test/widgets/route_map_test.dart) | IMPLEMENTADO | Integración local probada; disponibilidad de tiles no certificada. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-MAP-02](functional_requirements.md) | Geolocalización | [lib/services/location_service.dart](../../lib/services/location_service.dart); [lib/screens/home/home_screen.dart](../../lib/screens/home/home_screen.dart) | [test/services/location_service_test.dart](../../test/services/location_service_test.dart); [test/screens/home/home_screen_test.dart](../../test/screens/home/home_screen_test.dart) | IMPLEMENTADO | Gateway simulado; permisos y precisión requieren prueba en dispositivo. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-MAP-03](functional_requirements.md) | Búsqueda | [lib/services/place_suggestion_service.dart](../../lib/services/place_suggestion_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/services/place_suggestion_service_test.dart](../../test/services/place_suggestion_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart) | IMPLEMENTADO | Pruebas con respuestas simuladas; cobertura geográfica real no verificada. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE3 | [RF-MAP-04](functional_requirements.md) | Geocodificación | [lib/services/geocoding_service.dart](../../lib/services/geocoding_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/services/geocoding_service_test.dart](../../test/services/geocoding_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart) | IMPLEMENTADO | Consulta limitada a Colombia; no es motor de recomendaciones. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-MAP-05](functional_requirements.md) | Selección | [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart) | [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart) | IMPLEMENTADO | Capacidad de RutasScreen; no implica cálculo OSRM en esa pantalla. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE3 | [RF-ROUTE-01](functional_requirements.md) | Planificación | [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart) | IMPLEMENTADO | Una ruta, alternatives=false; sin comparación ni multimodalidad. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE3, OE4 | [RF-ROUTE-02](functional_requirements.md) | Resultados | [lib/models/route_result.dart](../../lib/models/route_result.dart); [lib/widgets/route_map.dart](../../lib/widgets/route_map.dart); [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart) | [test/widgets/route_map_test.dart](../../test/widgets/route_map_test.dart); [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart) | IMPLEMENTADO | Duración estimada, no tráfico observado ni hora de llegada garantizada. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-ROUTE-03](functional_requirements.md) | Estado de ruta | [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart); [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart) | [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart); [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart) | PARCIAL | Home invalida en cada notificación del controlador sin comparar texto. PR #21 excluido; no acreditar sus regresiones. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-ROUTE-04](functional_requirements.md) | Planificación | [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart) | IMPLEMENTADO | No garantiza disponibilidad del proveedor. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE4 | [RF-ROUTE-05](functional_requirements.md) | Catálogo | [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart); [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart) | [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart) | PARCIAL | Tests inyectan catálogo; sin prueba de datos remotos ni cobertura específica completa del filtro. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RF-ROUTE-06](functional_requirements.md) | Catálogo | [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart); [lib/screens/admin/rutas/rutas_admin_screen.dart](../../lib/screens/admin/rutas/rutas_admin_screen.dart) | No identificada. | PARCIAL | Sin pruebas dedicadas de persistencia/autorización; activa no significa servicio disponible. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE4 | [RF-UI-01](functional_requirements.md) | Navegación | [lib/widgets/app_navigation_drawer.dart](../../lib/widgets/app_navigation_drawer.dart); [lib/screens/home/home_screen.dart](../../lib/screens/home/home_screen.dart) | [test/screens/home/home_screen_test.dart](../../test/screens/home/home_screen_test.dart) | IMPLEMENTADO | Prueba parcial de navegación; ocultar menú no demuestra seguridad del backend. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE4 | [RF-UI-02](functional_requirements.md) | Interfaz | [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart); [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart) | IMPLEMENTADO | Comprensión por público general pendiente de evaluación con usuarios. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE3 | [RF-MOB-01](functional_requirements.md) | Recomendaciones | [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/models/perfil_model.dart](../../lib/models/perfil_model.dart) | No identificada. | PENDIENTE | No se encontró modelo de recomendación, preferencias de movilidad ni ranking; evidencia citada delimita lo existente. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE1, OE3, OE4 | [RF-MOB-02](functional_requirements.md) | Información de movilidad | [lib/models/ruta_model.dart](../../lib/models/ruta_model.dart); [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart) | No identificada. | PENDIENTE | Catálogo sin horarios; OSRM usa driving fijo. Fuentes y criterios por definir. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2 | [RNF-PERF-01](non_functional_requirements.md) | Búsqueda | [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart); [lib/screens/rutas/rutas_screen.dart](../../lib/screens/rutas/rutas_screen.dart) | [test/screens/rutas/rutas_screen_test.dart](../../test/screens/rutas/rutas_screen_test.dart) | IMPLEMENTADO | Los temporizadores observados son decisiones técnicas, no SLA. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RNF-PERF-02](non_functional_requirements.md) | Servicios | [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/services/geocoding_service.dart](../../lib/services/geocoding_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/services/place_suggestion_service_test.dart](../../test/services/place_suggestion_service_test.dart) | PARCIAL | Nominatim no impone timeout propio; cobertura depende del llamador. Sin medición de latencia real. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2 | [RNF-SEC-01](non_functional_requirements.md) | Seguridad | [lib/services/perfil_service.dart](../../lib/services/perfil_service.dart); [lib/services/ruta_service.dart](../../lib/services/ruta_service.dart) | No identificada. | NO VERIFICADO | No se localizaron políticas SQL/RLS ni implementación de crear-usuario; verificar backend. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RNF-SEC-02](non_functional_requirements.md) | Privacidad | [lib/services/location_service.dart](../../lib/services/location_service.dart); [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [README.md](../../README.md) | [test/services/location_service_test.dart](../../test/services/location_service_test.dart) | PARCIAL | Permisos implementados; política de retención/consentimiento y tratamiento remoto no verificada. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE4 | [RNF-USA-01](non_functional_requirements.md) | Interfaz | [lib/widgets/route_result_card.dart](../../lib/widgets/route_result_card.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart); [lib/main.dart](../../lib/main.dart) | [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart) | PARCIAL | Resumen probado a 390, 768 y 1440 px; no equivale a auditoría responsive global. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE4 | [RNF-USA-02](non_functional_requirements.md) | Interfaz | [lib/widgets/route_map.dart](../../lib/widgets/route_map.dart); [lib/widgets/route_planner_form.dart](../../lib/widgets/route_planner_form.dart) | [test/widgets/route_map_test.dart](../../test/widgets/route_map_test.dart); [test/widgets/route_planner_form_test.dart](../../test/widgets/route_planner_form_test.dart) | PARCIAL | Semántica parcial; faltan usuarios, lector de pantalla, teclado y contraste. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2 | [RNF-MAINT-01](non_functional_requirements.md) | Arquitectura | [lib/models/route_result.dart](../../lib/models/route_result.dart); [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/widgets/map_search_panel.dart](../../lib/widgets/map_search_panel.dart) | [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/screens/home/route_flow_test.dart](../../test/screens/home/route_flow_test.dart) | IMPLEMENTADO | Existe legado Google y duplicación Home/Rutas; no se acredita cobertura total. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE3 | [RNF-MAINT-02](non_functional_requirements.md) | Calidad | [lib/services/osrm_routing_service.dart](../../lib/services/osrm_routing_service.dart); [lib/services/geocoding_service.dart](../../lib/services/geocoding_service.dart); [lib/services/place_suggestion_service.dart](../../lib/services/place_suggestion_service.dart) | [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart); [test/services/geocoding_service_test.dart](../../test/services/geocoding_service_test.dart); [test/services/place_suggestion_service_test.dart](../../test/services/place_suggestion_service_test.dart) | IMPLEMENTADO | Validación estructural no demuestra exactitud geográfica. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2, OE4 | [RNF-COMP-01](non_functional_requirements.md) | Plataformas | [pubspec.yaml](../../pubspec.yaml); [README.md](../../README.md) | [test/widgets/route_result_card_test.dart](../../test/widgets/route_result_card_test.dart) | NO VERIFICADO | Tamaños de widget no prueban compilación ni funcionamiento nativo; matriz objetivo pendiente. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |
| OE2 | [RNF-MAINT-03](non_functional_requirements.md) | Operación | [lib/config/osrm_config.dart](../../lib/config/osrm_config.dart); [README.md](../../README.md) | [test/services/osrm_routing_service_test.dart](../../test/services/osrm_routing_service_test.dart) | PARCIAL | Endpoint configurable; capacidad, disponibilidad y operación productiva no verificadas. | PENDIENTE DE VERIFICACIÓN FDC-124; sin sección institucional asignada. |

## Variables relacionadas

| Variable | Objetivo provisional | Requisitos relacionados | Estado | Verificación institucional |
| --- | --- | --- | --- | --- |
| [VM-01](mobility_variables.md) Coordenadas actuales | OE2, OE3 | RF-MAP-02 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-02](mobility_variables.md) Origen | OE2, OE3 | RF-ROUTE-01, RF-ROUTE-03 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-03](mobility_variables.md) Destino | OE2, OE3 | RF-ROUTE-01, RF-ROUTE-03 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-04](mobility_variables.md) Nombre y contexto del lugar | OE2, OE4 | RF-MAP-03, RF-MAP-04 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-05](mobility_variables.md) Geometría | OE2, OE3 | RF-ROUTE-02 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-06](mobility_variables.md) Distancia | OE3, OE4 | RF-ROUTE-02 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-07](mobility_variables.md) Duración estimada | OE3, OE4 | RF-ROUTE-02 | IMPLEMENTADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-08](mobility_variables.md) Modo de transporte | OE3 | RF-MOB-02 | PARCIAL | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-09](mobility_variables.md) Metadatos del catálogo | OE4 | RF-ROUTE-05 | PARCIAL | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-10](mobility_variables.md) Preferencias de movilidad | OE1, OE3 | RF-MOB-01 | PENDIENTE | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-11](mobility_variables.md) Horarios | OE1, OE3 | RF-MOB-02 | PENDIENTE | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-12](mobility_variables.md) Alternativas y puntuación | OE3 | RF-MOB-01 | PENDIENTE | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-13](mobility_variables.md) Condiciones de circulación | OE1, OE3 | RF-MOB-01 (candidato por validar) | NO VERIFICADO | PENDIENTE DE VERIFICACIÓN FDC-124 |
| [VM-14](mobility_variables.md) Oferta de transporte | OE1, OE3 | RF-MOB-02 (candidato por validar) | NO VERIFICADO | PENDIENTE DE VERIFICACIÓN FDC-124 |

## Auditoría específica de OE3

El flujo de Home obtiene ubicación o un origen manual, resuelve lugares y solicita a OSRM una ruta vehicular. Valida GeoJSON y métricas, muestra geometría completa, distancia y duración estimada. Esto ofrece entradas y cálculo de recorrido útiles para un futuro modelo; no constituye por sí mismo personalización ni evidencia de OE3 completo.

OSRM recibe coordenadas y usa driving, alternatives=false, steps=false, overview=full y geometries=geojson. Consume la primera ruta. No se identificó comparación de candidatas, preferencias de movilidad, función de puntuación, recomendación de horarios/modos ni evaluación de calidad de recomendaciones. Perfil contiene identidad y rol, no preferencias. Catálogo contiene descripciones y estado administrativo, no horarios ni oferta operativa.

Brechas provisionales: contrastar OE3 con FDC; definir variables y fuentes autorizadas; definir criterios de personalización y comparación; implementar modelo explicable; establecer evaluación con evidencia y usuarios. No se prescribe algoritmo ni API sin decisiones aprobadas. OE3 queda técnicamente parcial respecto de la referencia del coordinador y académicamente pendiente.

## Diferencias entre módulos y trabajos independientes

Home/MapSearchPanel integra OSRM. RutasScreen conserva catálogo, geocodificación, selección por tap y aviso de cálculo pendiente. No atribuirle el routing de Home. RoutePlannerController, GoogleRoutesService y utilidades Google son legado con tests, no el motor activo de Home. La suite total incluye ese legado.

En MapSearchPanel, los listeners de origen/destino llaman a _invalidate sin comprobar cambio real del texto. Esto justifica RF-ROUTE-03 parcial. No se incorporó PR #21 ni sus dos regresiones. No se modificó el servicio Photon ni se incorporó trabajo de fix/photon-place-suggestions.

No se encontraron políticas SQL/RLS ni implementación de la función remota crear-usuario dentro del repositorio inspeccionado. La interfaz de roles y la integración Supabase no acreditan autorización remota. Puntos cercanos en el menú tampoco demuestra un inventario geográfico disponible.

## Contraste institucional posterior

Al recibir FDC-124: registrar ruta, título y versión; transcribir objetivos y secciones pertinentes; contrastar cada ID conservándolo; completar referencia institucional de cada fila; confirmar, corregir o descartar propuestas con justificación; aprobar variables y criterios; revisar estados académicos independientemente de estados técnicos. No declarar cierre académico antes de ese contraste.

## Validación de esta entrega

Ejecución local del 16 de septiembre de 2026 sobre el baseline e1883e2 con los cuatro documentos provisionales:

- `flutter analyze`: sin problemas, salida 0.
- `flutter test`: 89 pruebas aprobadas, salida 0. Incluye pruebas de legado Google; no incluye las dos regresiones del PR #21.
- Avisos informativos de flutter_map sobre servidores públicos de tiles; no provocaron fallos.
- Enlaces relativos a código, pruebas y documentos comprobados contra archivos existentes.
- No se ejecutaron pruebas contra proveedores reales, validación de RLS ni compilaciones nativas.

| Inventario | Total | IMPLEMENTADO | PARCIAL | PENDIENTE | NO VERIFICADO | NO APLICA |
| --- | --- | --- | --- | --- | --- | --- |
| RF | 20 | 10 | 8 | 2 | 0 | 0 |
| RNF | 10 | 3 | 5 | 0 | 2 | 0 |
| Variables | 14 | 7 | 2 | 3 | 2 | 0 |

Los 44 elementos permanecen PENDIENTE DE VERIFICACIÓN FDC-124 independientemente de su estado técnico. B1 permanece EN REVISIÓN — PENDIENTE CONTRASTE CON FDC-124.
