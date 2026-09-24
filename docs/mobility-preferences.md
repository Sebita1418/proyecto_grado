# B3 / B6 — Preferencias de movilidad

Clasificación: DERIVADO FUNCIONAL / DERIVADO TÉCNICO / UX.
PENDIENTE DE VERIFICACIÓN FDC-124. No se modifica la línea base documental B1.
Baseline de implementación B3: `b321a75a6e5556c43ab6846c6f10fdb37865a261`.

## Alcance respaldado por el dominio

La pantalla consume `TransportMode`: driving, walking, cycling y publicTransport.
La selección múltiple corresponde a `MobilityContext.allowedModes`, que exige
un conjunto no vacío y lo copia como inmutable. No se crea otro modelo de dominio.
RF-MOB-01, RF-MOB-02 y VM-08/VM-10 son referencias provisionales, no requisitos
institucionales confirmados. La evidencia concreta del alcance es el contrato
actual, descrito en [mobility-domain.md](mobility-domain.md).

No existen clases RecommendationRequest/RecommendationResult. Sus equivalentes
son `MobilityContext` más `List<RouteOption>` como entradas de
`MobilityRecommendationEngine.recommend`, y `MobilityRecommendation` como salida.
`RecommendationFactor.distance/duration` clasifica razones de una decisión;
no define prioridades elegibles ni pesos. Por eso no se implementan preferencias
de tiempo, distancia, congestión, costo o ahorro.

## Navegación y estado

Acceso: Home → Drawer → Perfil → Preferencias de movilidad. Home y Drawer no
cambian. Antes de B6 las preferencias eran locales a la experiencia de pantalla:
al salir se perdía incluso la confirmación. Después de B6 se persisten localmente
en el dispositivo y se cargan al abrir. Sin datos guardados comienza vacío.
Confirmar exige al menos un modo y guarda antes de actualizar la confirmación.
Deshacer restaura la última selección confirmada o el conjunto vacío inicial;
no escribe en almacenamiento. Salir descarta los cambios sin confirmar y reabrir
recupera lo guardado.

El callback opcional `onConfirmed` entrega un `Set<TransportMode>` inmutable,
compatible directamente con `MobilityContext.allowedModes`. El acceso desde
Perfil no conecta ningún consumidor todavía. No se fabrica un contexto con
coordenadas o fecha ficticias ni se invoca un motor.

B6 reutiliza `shared_preferences 2.5.5`, ya instalado, reclasificado de
`dev_dependencies` a `dependencies` mediante `flutter pub add`. No agrega paquetes
ni cambia versiones. `MobilityPreferencesService` separa UI y almacenamiento y se
puede inyectar en la pantalla para pruebas. Usa la API existente SharedPreferences
con recarga previa a cada lectura para evitar datos de caché de escrituras fallidas.
La clave `mobility_preferences.modes.v1` contiene los nombres de `TransportMode`
(`driving`, `walking`, `cycling`, `publicTransport`), nunca etiquetas traducidas
ni índices. Renombrar un valor del enum requerirá una migración explícita.
Valores desconocidos, duplicados o un formato obsoleto se ignoran; si no queda
ningún modo conocido, la selección es vacía. Cargar no reescribe los datos.

La carga muestra progreso y tiene un límite de ocho segundos. Un fallo permite
elegir y confirmar una nueva selección con un mensaje visible. Durante el guardado
se deshabilitan selección y acciones para evitar escrituras superpuestas desde
la pantalla. Solo una escritura exitosa actualiza la confirmación y emite el
callback inmutable. Si falla, mantiene el borrador, informa y permite reintentar
o deshacer. Se capturan excepciones de almacenamiento, no errores de programación.
Salir mientras hay una escritura pendiente no cancela una confirmación solicitada.
SharedPreferences es apropiado para preferencias simples, no datos críticos con
garantía de durabilidad transaccional ante cierre abrupto.

La preferencia es del dispositivo/instalación (del almacenamiento del navegador
en web), compartida entre cuentas que usen esa instalación. No hay separación
por usuario ni sincronización remota de preferencias en B6. El perfil Supabase
contiene identidad, rol y estado; no se modifica su esquema.

## Relación provisional con objetivos y Diseño A

B3 aporta provisionalmente a OE3 como captura de modos elegidos compatible con
el contrato del dominio, y a OE4 como interfaz accesible desde Perfil. Es un
avance funcional/técnico y UX; no acredita cumplimiento completo de esos objetivos
ni constituye un motor de recomendaciones. FDC-124 no está disponible en el
repositorio y deberá contrastarse posteriormente; no se crean requisitos
clasificados como FDC EXPLÍCITO.

La pantalla hereda el tema Material 3 de la aplicación. Mantiene la baja carga
visual de Diseño A con un grupo de opciones, mensajes de estado y dos acciones.
El contenido permite desplazamiento, limita su ancho a 640 px y adapta los botones
con Wrap. Las pruebas cubren anchos de 320, 390, 768 y 1440 px con texto al 150 %.

## Brechas

- Definir tratamiento por usuario y sincronización si se requieren posteriormente.
- Conectar selección confirmada con un contexto de viaje real y un consumidor.
- Implementar y validar motor y fuentes de alternativas; representar un modo
  no implica que un proveedor lo soporte o que exista oferta disponible.
- Contrastar preferencias y alcance con FDC-124.

B3 no modifica el cálculo OSRM actual ni produce recomendaciones personalizadas.
B6 tampoco conecta preferencias con routing: todavía NO alimentan un motor
productivo de recomendaciones y todavía NO constituyen personalización inteligente.
La relación con FDC-124 sigue pendiente de contraste.

## Auditoría y alcance de B6

Baseline: `develop@a386094e347b4c7b7f578a8f860612c81d9caf97`.
Responsable: Brayan. Rama: `feature/mobility-preferences-persistence`.
No existía servicio de preferencias ni almacenamiento de movilidad en Supabase.
Se conservan Diseño A, el enum y la semántica de Deshacer de B3.
Perfil no requiere cambios de producción. Su prueba está realmente en
`test/perfil/perfil_screen_test.dart`; se actualiza la expectativa histórica
de pérdida al salir porque contradice la persistencia requerida por B6.
No se modifican archivos del PR #27, `lib/mobility/**` ni la matriz de trazabilidad.

## Validación local de B6

- Pruebas específicas del servicio, pantalla y Perfil: 27 aprobadas
  (11 del servicio, 13 de preferencias y 3 de Perfil).
- Cobertura: almacenamiento vacío, múltiples modos, actualización, identificadores
  obsoletos, errores, escritura rechazada, carga agotada, respuesta tardía,
  confirmación, borradores, Deshacer, reapertura y salida durante operaciones.
- Layout: 320, 390, 768 y 1440 px, texto al 150 %, sin overflow.
- `flutter pub get`: correcto; se conserva la versión 2.5.5 del paquete.
- `flutter analyze`: falla exclusivamente por los cinco errores conocidos de
  `test/widgets/route_summary_card_test.dart`, que importa un widget inexistente.
- `flutter test`: 165 pruebas aprobadas; único fallo al compilar ese test histórico.
- Validación equivalente con lista explícita obtenida mediante `git ls-files`
  más los nuevos archivos B6: `dart analyze` sobre 71 Dart sin problemas y
  `flutter test` sobre 26 archivos con 165 pruebas aprobadas.
- `git diff --check`: correcto.
- `flutter build web --no-pub`: correcto, salida en `build/web`; comprobación
  preliminar de WebAssembly exitosa.

El archivo histórico permanece intacto, no rastreado y fuera del commit.
No se modificaron exclusiones del analizador ni se movió el archivo para validar.

## Validación local de B3

- `flutter test test/screens/preferences`: 7 pruebas aprobadas.
- `flutter test test/perfil/perfil_screen_test.dart`: 3 pruebas aprobadas;
  incluye navegación, descarte al salir y estados Activa/Inactiva tras scroll.
- Suite de los 24 archivos de tests que forman la entrega: 124 pruebas aprobadas.
- `dart analyze` con la lista explícita de 65 archivos Dart versionados del
  baseline y los 2 nuevos de B3: sin problemas.
- `flutter build web --no-pub`: compilación correcta en `build/web`.
- `git diff --check`: sin errores de espacios en blanco.

El test histórico no rastreado `test/widgets/route_summary_card_test.dart` queda
fuera de estas validaciones y de la entrega; no se modifica. Las pruebas de UI
no sustituyen una evaluación con usuarios, teclado o lector de pantalla.
