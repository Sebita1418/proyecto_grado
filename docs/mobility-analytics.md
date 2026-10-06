# Analítica histórica de movilidad

## Objetivo y estado

Implementación aditiva sobre `feature/mobility-analytics`, baseline `ac75248`
(`feat: complete mobility objectives experience (#49)`). Antes de editar:
rama correcta, árbol limpio, sin merge activo y `git diff --check` sin errores.
No se hicieron commit, push, PR ni operaciones remotas en Supabase.

El bloque procesa observaciones reales de reportes registrados. No mide flujo
vehicular ni confirma accidentes por autoridad. Su puesta en funcionamiento
histórica requiere aplicar manualmente la propuesta SQL y validar sus permisos.

## Auditoría de fuente y esquema versionado

Se inspeccionaron modelos, servicios, controlador operacional, Home, Drawer,
tema, documentación, pruebas, `pubspec.yaml` y SQL versionado. No existe una
dependencia de gráficos. Se usan widgets Flutter simples.

`docs/supabase/road_incident_reports.sql` define `public.reportes_viales`:

| Campo | Tipo / restricciones | Uso analítico |
|---|---|---|
| id | UUID, clave primaria | Solo orden interno SQL; no se devuelve |
| usuario_id | UUID, FK auth.users, borrado en cascada | No se consulta ni devuelve |
| tipo | text: accident, congestion, road_work, road_closed, hazard, other | Distribución |
| latitud / longitud | double precision, límites geográficos | No se consulta |
| descripcion | text opcional, máximo 200 caracteres | No se consulta |
| creado_en | timestamptz, default now() | Selección y distribución temporal |
| expira_en | timestamptz, default now() + 6 horas, posterior a creación | Actividad / expiración |
| estado | text: activo, cancelado | Clasificación de vigencia |

Esta es evidencia del repositorio, **no certificación del esquema remoto**.
`RoadIncidentService.fetchActiveReports()` consulta hasta 100 activos, ordenados
por creación descendente. RLS restringe a activos no expirados; el modelo y
controlador vuelven a comprobar expiración. Realtime invalida la lista activa.
No hay consulta histórica existente. Estos contratos permanecen sin cambios.

## Arquitectura y modelos

`reportes_viales` → RPC histórica → `SupabaseMobilityAnalyticsRepository` →
`AnalyticsObservation` / `AnalyticsBatch` → `MobilityAnalyticsEngine` →
`MobilityAnalyticsSnapshot` → `MobilityAnalyticsController` → pantalla.

El dominio bajo `lib/mobility/analytics/` no importa Flutter, Supabase ni red.
El repositorio abstracto permite sustituir la fuente. La implementación usa el
SDK existente y timeout de 20 segundos. El controlador inyecta reloj y fuente,
gestiona idle/loading/data/empty/error, selección y retry. Un número de revisión
descarta respuestas antiguas y respuestas posteriores a dispose.

El snapshot tiene campos finales y colecciones inmutables. Contiene consulta,
fecha de evaluación, disponibilidad, total, activos, expirados, cancelados,
categorías, franjas, registros inválidos y señal de truncamiento. No contiene
autores, coordenadas, descripciones, identificadores ni rutas personales.

## Periodos y procesamiento

Selector: últimas 24 horas, 7 días y 30 días. Intervalo UTC `[inicio, fin)`:
incluye inicio y excluye fin. El reloj se toma una vez por consulta. El modelo
admite un intervalo explícito de hasta 30 días para pruebas; no se añadió
selector personalizado para mantener el alcance estable.

El motor filtra por creación y suma las categorías reales. Para 24 h crea 24
franjas consecutivas de una hora; para 7/30 días, franjas consecutivas de 24 h
desde el inicio del periodo. Son ventanas móviles UTC, no días de calendario
local. Incluye franjas sin observaciones y admite un último tramo menor.

Activos: `estado == activo && expira_en > evaluated_at`, usando la evaluación
del servidor incluida en la respuesta. Expirados: estado activo con fecha de
expiración alcanzada. Cancelados se contabilizan aparte, incluso si expiraron.
Así total = activos + expirados + cancelados para observaciones válidas.

La categoría predominante requiere al menos dos observaciones y ganador único.
Los empates y muestras insuficientes se explicitan. La mayor actividad usa el
máximo conteo temporal; conserva todas las franjas empatadas. Los porcentajes
se calculan sobre observaciones válidas recibidas. No son porcentajes del
tránsito total. Complejidad: O(n + b + c), sin ordenar observaciones en cliente.

## Calidad, errores y cobertura

Consulta completa sin filas: EMPTY, «No hay reportes registrados para este
periodo», con cobertura. Fallo de red, permisos, RPC inexistente o contrato
inválido: UNAVAILABLE/error, «No fue posible cargar la analítica», Reintentar.
Los errores no generan snapshots vacíos ni tarjetas con cero.

Filas inválidas o fuera de ventana se excluyen y cuentan. Si existen exclusiones
o truncamiento, PARTIAL incluso con cero observaciones válidas. Se muestra una
advertencia y todos los indicadores corresponden únicamente a la muestra.
AVAILABLE significa consulta completa bajo este contrato, no exhaustividad del
tránsito, representatividad ciudadana ni retención histórica permanente.

Cobertura muestra intervalo UTC, observaciones válidas, evaluación del servidor,
estado, exclusiones, truncamiento, expirados/cancelados y fuente. No se asegura
una fecha mínima de retención: el borrado de usuarios puede borrar sus reportes.

## Supabase, RLS y privacidad

`docs/supabase/mobility_analytics.sql` **requiere aplicación manual en Supabase**.
No fue ejecutado. Se necesita porque la política operacional impide históricos.
La propuesta crea índice de creación y función `security definer`, con
`search_path` vacío, referencias calificadas, sin SQL dinámico, validación de
`auth.uid()`, EXECUTE solo para authenticated y revocación para public/anon.
No desactiva RLS ni modifica la política de lectura operacional.

La función permite exclusivamente hasta 30 días por petición, dentro de los
últimos 31 días del servidor y hasta cinco minutos de tolerancia de reloj al fin.
Obtiene como máximo 5001 filas para detectar truncamiento y devuelve hasta 5000
en orden de creación/ID. Solo proyecta tipo, creación, expiración y estado.
La respuesta versión 1 incluye evaluación y truncamiento. No usa service-role
en Flutter ni abre SELECT histórico sobre la tabla a clientes.

El propietario de la función debe ser un rol confiable de migración/base de datos
capaz de leer las filas históricas, **nunca anon ni authenticated**. Verificar el
owner tanto antes como después de aplicar: `CREATE OR REPLACE FUNCTION` conserva
el propietario de una función existente; crearla por primera vez usa el rol que
ejecuta la creación. Revisar esquema, propiedad y permisos antes de aplicar.
El script revoca privilegios directos de authenticated antes de conceder EXECUTE,
además de revocar public/anon, para normalizar explícitamente esa concesión.
Verificar también permisos heredados y concesiones a otros roles existentes:
estas revocaciones no eliminan privilegios de roles ajenos a los enumerados.
La función es una concesión deliberada de lectura histórica minimizada mediante
RPC: no afirma que RLS original permita históricos. Aunque la UI agrega, la RPC
devuelve observaciones temporales individuales sin identidad; si se requiere
protección adicional frente a inferencia por baja densidad, evaluar agregación
en servidor y umbrales de publicación. No se presenta historial individual.

### Procedimiento manual de validación posterior

Esta revisión no aplica SQL ni certifica el backend remoto. Después de la
aplicación manual, realizar y registrar las siguientes comprobaciones:

1. Comprobar la función exacta
   `public.mobility_analytics_observations(timestamptz,timestamptz)` en el catálogo:
   retorna jsonb, es SECURITY DEFINER y tiene `search_path = ''`. Revisar su
   definición y confirmar referencias calificadas. Comprobar que RLS y las
   políticas operacionales de `public.reportes_viales` siguen intactas.
2. Comprobar owner antes/después, mediante `pg_catalog.pg_proc.proowner` y
   `pg_catalog.pg_roles`: debe ser el rol confiable de migración/base de datos
   aprobado, nunca anon/authenticated, y poder leer históricos. Si la función
   aún no existe antes de aplicar, comprobar el rol que ejecutará su creación.
3. Comprobar ACL de la función (`pg_catalog.pg_proc.proacl`) y privilegios
   efectivos con `pg_catalog.has_function_privilege`: authenticated tiene
   EXECUTE, anon no; PUBLIC no tiene concesión. Revisar membresías heredadas y
   cualquier grant previo a otros roles. Confirmar que no se añadió SELECT
   histórico directo sobre la tabla.
4. Probar RPC como anon y sin sesión: debe rechazarse. Probar también sin
   identidad JWT bajo authenticated en un entorno de prueba controlado: la
   comprobación `auth.uid()` debe rechazarlo con 42501. Una ejecución en el SQL
   Editor como administrador no sustituye estas pruebas de sesión.
5. Probar RPC con una sesión authenticated real: debe permitir una ventana
   válida, incluidos registros expirados conservados en el periodo. No crear
   datos ficticios ni usar credenciales administrativas desde Flutter.
6. Confirmar contrato versión 1 y que cada elemento de `observations` tiene
   exactamente `tipo`, `creado_en`, `expira_en`, `estado`; no contiene `id`,
   `usuario_id`, `latitud`, `longitud`, `descripcion` ni otros datos personales.
7. Confirmar ventanas móviles UTC de 24 h, 7 días y 30 días, con un mismo fin
   válido y límites `[inicio, fin)`. Probar rechazo de inicio igual/posterior al
   fin, duración mayor a 30 días, inicio anterior a 31 días y fin futuro mayor
   a cinco minutos. Probar los límites usando el reloj del servidor.
8. Confirmar límite de 5000 y `truncated` al existir la fila 5001, cuando los
   datos disponibles permitan comprobarlo. Ambos CTE ordenan por creación/ID;
   el agregado JSON también tiene ORDER BY explícito. ID se usa internamente y
   queda excluido por la lista blanca de campos del objeto JSON. Comprobar que
   el flujo operacional continúa ocultando los expirados por su RLS original.

Referencias técnicas: [seguridad y propietario de funciones PostgreSQL](https://www.postgresql.org/docs/current/sql-createfunction.html)
y [orden explícito de agregados JSON](https://www.postgresql.org/docs/current/functions-aggregate.html).

## UI y navegación

Nuevo acceso «Analítica de movilidad» en el Drawer de Home, con push de pantalla
independiente. Conserva accesos existentes. Home solo añade import/callback.
La pantalla reutiliza `MobilityDesign` y el tema heredado: tarjetas redondeadas,
insets y colores existentes. No añade dependencias ni modifica recomendación,
OSRM, RouteInsight, navegación, ubicación o búsqueda.

Diseño con scroll, ancho máximo 1120, selector Wrap, tarjetas Wrap y barras
proporcionales semánticas. Etiquetas y fechas pueden ocupar varias líneas.
Fuente y aviso: «Los indicadores representan actividad de reportes y no el flujo
total del tránsito». Actualización manual; no hay subscripción Realtime analítica.

## Pruebas y validación pendiente

`test/mobility/analytics/mobility_analytics_test.dart` incluye:

- Motor: vacío, una observación, categorías reales, predominio, empate,
  inmutabilidad, límites exactos, fuera de periodo, agrupación horaria/diaria,
  pico, vigencia/expiración/cancelación, UTC, orden independiente y determinismo.
- Repositorio con HTTP simulado: endpoint y parámetros, históricos expirados,
  mapeo, inválidos, vacío, truncamiento, contrato incompatible y error HTTP.
- Controller: estados, 24h/7d/30d, retry, respuesta obsoleta y dispose.
- UI: título, selector, carga, datos, vacío, error, retry, categorías, actividad,
  cobertura, fuente, aviso y scroll sin excepciones a 320/390/768/1440.
- Drawer: conserva reportes/perfil y ejecuta callback analítico.

El comando de formato explícito quedó sin salida unos 20 segundos; se interrumpió
según la instrucción del bloque. No se repitió ni se ejecutaron analyze/tests.
Por tanto **no se certifican formato, compilación, responsive ni pruebas verdes**.
`git diff --check` pasó durante la revisión estática. Para validar localmente:

```powershell
dart format lib/mobility/analytics/mobility_analytics.dart lib/mobility/analytics/mobility_analytics_repository.dart lib/services/supabase_mobility_analytics_repository.dart lib/controllers/mobility_analytics_controller.dart lib/screens/analytics/mobility_analytics_screen.dart lib/widgets/app_navigation_drawer.dart lib/screens/home/home_screen.dart test/mobility/analytics/mobility_analytics_test.dart
flutter test --no-pub test/mobility/analytics/mobility_analytics_test.dart test/reports test/screens/home
flutter analyze --no-pub
flutter test --no-pub
git diff --check
git status --short
```

SQL requiere comprobación separada: autenticado obtiene históricos expirados;
anónimo no puede ejecutar; ventanas inválidas fallan; respuesta no contiene
identidad; política operacional sigue ocultando expirados; >5000 filas produce
truncamiento. Las pruebas Dart simuladas no certifican estos permisos remotos.

## Inventario de evidencia

| Evidencia | Fuente | Procesamiento | Resultado | Limitación |
|---|---|---|---|---|
| Total de reportes | RPC sobre reportes_viales | Filtro [inicio, fin), conteo | Observaciones por periodo | Solo registros conservados y accesibles |
| Vigencia | estado y expira_en | Evaluación UTC del servidor | Activos/expirados/cancelados | No confirma incidente en campo |
| Categorías | tipo | Conteos y proporciones | Distribución y predominio | Reportes comunitarios, no tránsito real |
| Actividad temporal | creado_en | Franjas UTC horarias/diarias | Conteos, máximos y empates | Fecha del reporte, no hora confirmada del evento |
| Cobertura | Contrato RPC | Límite y validación | Complete/empty/partial; error unavailable | RPC y permisos aún requieren validación remota |
| Separación arquitectónica | Dominio/repositorio/controller/UI | Inyección y pruebas controladas | Comportamiento reproducible | Tests escritos, ejecución pendiente |

## Aporte académico, límites y futuro

Se distinguen datos operacionales (reportes activos para mapa), analítica de
movilidad (consulta histórica minimizada, procesamiento temporal, agregación,
indicadores y visualización) y capacidades Big Data a escala (no demostradas).
El bloque aporta trazabilidad de fuente, dimensión temporal, procesamiento
testeable y apoyo a decisiones sobre actividad de reportes. Este inventario
puede servir como insumo posterior para FDC-125; no crea ese documento.

No demuestra procesamiento masivo, predicción, ML, flujos de vehículos, velocidad,
demanda, pasajeros, congestión real ni mejoras automáticas de rutas. Supabase y
estadísticas no convierten el prototipo en plataforma Big Data industrial.

El límite explícito, índice y separación permiten evolución, pero no garantizan
rendimiento a gran escala: faltan mediciones, carga, planes de consulta, retención,
observabilidad y pruebas de privacidad. Un futuro incremento puede evaluar
agregaciones en servidor, paginación/snapshots consistentes, caché, calidad y
representatividad, privacidad por umbrales y validación con otras fuentes reales.
No usar históricos en recomendación/routing sin evaluación y evidencia aparte.
