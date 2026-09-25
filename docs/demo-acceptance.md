# Aceptación manual de la demo

Responsable: Sebastián. Rama: `feature/demo-flow-recovery-and-evidence`.
Baseline: `189cd0a1a208b45f03a05f104ab61716db7ee38a` (#33 integrado; 206 pruebas).

Todos los casos están **PENDIENTE**: no se ejecutó una demo manual en este incremento. Las pruebas automatizadas con dobles no permiten marcar APROBADO un caso manual. Registrar por ejecución: fecha, responsable, commit, plataforma/navegador, tamaño de pantalla, pasos efectivos, resultado y enlace a captura/video/log sin credenciales. Cambiar a APROBADO o FALLIDO solo después de ejecutar y adjuntar evidencia; si no se consigue la condición (por ejemplo, varias alternativas reales), conservar PENDIENTE y explicar el impedimento.

Usar una cuenta de prueba real autorizada y datos disponibles, sin alterar Supabase. Para fallos de proveedor, simular desconexión o bloqueo de la petición en el entorno de demo, registrar la condición y restablecerla. No publicar tokens, contraseñas, coordenadas privadas ni datos personales en las capturas.

| Caso | Pasos verificables | Resultado esperado | Evidencia a capturar | Estado |
| --- | --- | --- | --- | --- |
| A. Login real | Iniciar la app; ingresar con la cuenta autorizada; repetir con credenciales incorrectas. | Acceso válido abre Home; acceso inválido informa el fallo y permite corregir. No acreditar OAuth si solo se probó correo/contraseña. | Capturas de ambos resultados y plataforma, sin credenciales. | PENDIENTE |
| B. Home Diseño A | Abrir Home; revisar mapa, panel, botón de ubicación y Drawer; cerrar Drawer. | Mapa principal disponible, controles legibles, navegación sin bloquearlo. | Captura completa y video corto de apertura/cierre. | PENDIENTE |
| C. GPS | Permitir ubicación; pulsar Mi ubicación; repetir con permiso denegado o servicio apagado. | Con permiso válido se muestra ubicación; ante fallo se informa y permanece origen manual. | Capturas de permiso, marcador y fallback, omitiendo ubicación privada. | PENDIENTE |
| D. Origen manual | Sin GPS disponible, escribir origen y destino válidos en Home; calcular. | El origen manual permite consultar ruta vehicular sin depender de GPS, sujeto a elegibilidad. | Entradas, resultado y registro de consultas. | PENDIENTE |
| E. Photon | Escribir al menos tres caracteres; esperar sugerencias; seleccionar un lugar y calcular con ambos puntos seleccionados. | Se usan coordenadas elegidas; no se llama Nominatim para puntos ya seleccionados. | Sugerencias, selección y panel Network sin datos sensibles. | PENDIENTE |
| F. Nominatim | Escribir puntos sin seleccionar Photon; calcular en Home y usar Mostrar puntos en Rutas. | Home resuelve texto y calcula; Rutas solo localiza marcadores. Búsquedas fallidas permiten corregir/reintentar. | Peticiones y diferencia visual entre pantallas. | PENDIENTE |
| G. Alternativas OSRM | Con driving elegible, calcular en Home entre puntos válidos. | Se solicitan alternativas reales driving; mapa, distancia y duración estimada son coherentes con la candidata seleccionada. | Petición/respuesta OSRM y resumen, sin afirmar tráfico actual. | PENDIENTE |
| H. Una alternativa | Encontrar y registrar una consulta cuya respuesta OSRM contenga una candidata. | Mensaje de una sola ruta vehicular y explicación de única candidata elegible; sin comparación ficticia ni selector de varias. | Respuesta con longitud 1 y captura del resumen. | PENDIENTE |
| I. Varias alternativas | Registrar una consulta con más de una candidata; abrir lista y desplazarse. | Se conservan candidatas del proveedor; comparación de duración/distancia y diferencias visibles; ninguna alternativa inventada. | Respuesta, hoja de alternativas y métricas. | PENDIENTE |
| J. Ruta sugerida | Comparar métricas originales de las candidatas con la sugerencia inicial. | Regla provisional: menor duración, luego menor distancia, luego orden proveedor. Explicación atribuida al motor y límites claros; no IA ni optimalidad global. | Candidatas, cálculo de verificación y «Ruta sugerida». Si no hay empates reales, no dar por ejecutados los desempates. | PENDIENTE |
| K. Selección manual | Elegir otra candidata y, después, elegir manualmente la sugerida. | Resumen indica «Selección manual»; tarjeta mantiene «Ruta seleccionada»; mapa/detalles sincronizados y sin nuevas consultas. | Video y contador Network antes/después. | PENDIENTE |
| L. Invalidación | Tras un resultado, editar origen o destino; repetir cambiando GPS/manual; cambiar solo cursor como control. | Edición real invalida resultado/sugerencia; cursor sin edición los conserva. | Video del cambio y ausencia/presencia de geometría. | PENDIENTE |
| M. Preferencias con driving | Desde Perfil confirmar driving; salir/reabrir; calcular. Probar además una instalación sin modos guardados. | Persistencia local y elegibilidad vehicular. Sin modos guardados se comunica driving por defecto sin atribuir la elección al usuario. | Confirmación, reapertura y resumen; identificar instalación usada. | PENDIENTE |
| N. Preferencias sin driving | Guardar únicamente walking/cycling/publicTransport; volver a Home y recalcular; después guardar driving y recalcular. | Sin driving no se selecciona ruta vehicular ni se simulan otros modos; se conservan entradas para recuperar. Tras incluir driving se puede evaluar. | Aviso de incompatibilidad, mapa sin ruta y recuperación. | PENDIENTE |
| O. Perfil | Provocar fallo de carga o ausencia de datos; pulsar Perfil varias veces; reintentar; restaurar acceso y abrir Perfil. | Aviso comprensible, mapa utilizable, una carga a la vez, sin SnackBars de perfil duplicados; al recuperar se puede navegar. | Video de fallo, carga, reintento y Perfil recuperado. | PENDIENTE |
| P. RutasScreen | Abrir catálogo; filtrar nombre/origen/destino/descripción, variar mayúsculas y probar sin coincidencias; recargar. Seleccionar puntos por Photon/tap o texto; usar Mostrar puntos. Retardar Nominatim en cada extremo más de 10 s y reintentar. | Filtro conserva consulta al recargar; carga/error comprensibles. «Localizando…» durante espera; timeout libera controles. Solo marcadores, sin OSRM; explicación remite a Mapa / Inicio. Respuesta tardía no cambia nueva selección. | Video del filtro/recarga, estados del botón, timeout, marcadores y Network. | PENDIENTE |
| Q. Puntos cercanos | Abrir desde Drawer, revisar categorías y volver por botón/atrás. | Pantalla «Aún no disponible», sin búsqueda real ni resultados ficticios; vuelve al mapa. | Captura del límite y navegación. | PENDIENTE |
| R. Logout/login | Cerrar sesión con confirmación; iniciar otra vez; revisar Perfil y preferencias en la misma instalación. | Sesión anterior cerrada y perfil de la sesión vigente. Preferencias siguen siendo por instalación, potencialmente compartidas entre cuentas; no se presentan como sincronizadas por usuario. | Video sin credenciales y comparación de estado local. | PENDIENTE |
| S. Errores de proveedor | Bloquear por separado Photon, Nominatim y OSRM; ejecutar acción correspondiente; restaurar conexión y reintentar. | Errores comprensibles, carga termina según límite de cada etapa y no queda ruta anterior como vigente. No se muestran detalles internos en Rutas. Un fallo de lectura de preferencias tampoco equivale a ausencia de modos. | Capturas, tiempos observados y solicitudes bloqueadas/restauradas. Registrar aparte si el fallo de almacenamiento no se pudo inducir. | PENDIENTE |
| T. Responsive básico | Probar 320, 390, 768 y 1440 px, texto al 150 %; revisar Home con aviso de Perfil, Rutas, selector y detalles. | Texto y acciones alcanzables, sin overflow; mapa sigue utilizable y listas desplazables. | Captura por ancho/escala y video de scroll. | PENDIENTE |

## Evidencia automatizada y límites

El baseline #33 tiene 206 pruebas aprobadas. Este incremento añade regresiones de recuperación de Perfil, Nominatim por extremo, concurrencia, catálogo y etiquetas del formulario. Los tests de servicios usan dobles; las solicitudes HTTP reales no forman parte de esta validación. La suite no certifica Login real, disponibilidad de OSRM/tiles/Photon/Nominatim, RLS, precisión del GPS, operación nativa ni evaluación con usuarios.

RF-MOB-01: **PARCIAL** por alcance vehicular, elegibilidad limitada al modo, falta de personalización completa/evaluación y contraste FDC. RF-MOB-02: **PENDIENTE** sin horarios ni comparación productiva entre medios. No hay IA, ruta óptima garantizada, tráfico en tiempo real ni sincronización Supabase de preferencias. Ver [matriz](requirements/traceability_matrix.md) y [modelo](recommendation-model.md).

## Validación automatizada del incremento (2026-09-25)

- `dart format` sobre los seis Dart autorizados: aplicado.
- `flutter analyze --no-pub`: 0 incidencias, salida 0.
- `flutter test --no-pub`: **229 pruebas aprobadas**, salida 0; baseline 206 más 23 nuevas (8 Home, 14 Rutas, 1 formulario).
- `git diff --check`: limpio.
- Los tests previos de `route_flow_test.dart` se conservan sin editar, incluidos 320/390/768/1440 px con texto ampliado. El aviso de Perfil ocupa una zona acotada y desplazable sobre el mapa, sin reducir las dimensiones del panel de rutas.
- 339 enlaces locales de los ocho documentos revisados: destinos existentes.
- Advertencias observadas: aviso informativo de flutter_map sobre tiles públicos OSM y conversión LF/CRLF anunciada por Git; no son fallos del análisis ni de la suite.
- No se ejecutó aceptación manual, HTTP real, build web/nativo ni validación de Supabase remoto. Los 20 casos A–T permanecen PENDIENTE.

## Referencia #27

Se rescatan selectivamente mensajes/reintento de Perfil, labels y timeout de Rutas, adaptados al estado actual. El aviso de Perfil se implementa como banner persistente para no encolar SnackBars. Quedan superados el título «Ruta calculada» y las premisas anteriores a alternativas/recomendación. Se descartan de este incremento los cambios a MapSearchPanel y RouteResultCard por estar fuera del alcance permitido. No se fusiona ni se aplica cherry-pick de #27.
