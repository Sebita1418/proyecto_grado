# B3 — Preferencias de movilidad

Clasificación: DERIVADO FUNCIONAL / DERIVADO TÉCNICO / UX.
PENDIENTE DE VERIFICACIÓN FDC-124. No se modifica la línea base documental B1.
Baseline de implementación: `b321a75a6e5556c43ab6846c6f10fdb37865a261`.

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
cambian. Al entrar no hay modos preseleccionados: no se supone una preferencia.
Confirmar exige al menos un modo. Deshacer restaura la última selección confirmada
o el conjunto vacío inicial. Salir descarta todo el estado de esta pantalla,
incluida la selección confirmada. Reabrir comienza de nuevo.

El callback opcional `onConfirmed` entrega un `Set<TransportMode>` inmutable,
compatible directamente con `MobilityContext.allowedModes`. El acceso desde
Perfil no conecta ningún consumidor todavía. No se fabrica un contexto con
coordenadas o fecha ficticias ni se invoca un motor.

Existe una dependencia shared_preferences pero no un mecanismo de preferencias
de movilidad implementado. Su presencia no define una política de persistencia.
El perfil Supabase actual contiene identidad, rol y estado, no preferencias.
Se mantiene estado local de UI sin escritura local persistente ni remota.

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

- Acordar persistencia, ciclo de vida y tratamiento por usuario antes de conservar
  elecciones fuera de la pantalla.
- Conectar selección confirmada con un contexto de viaje real y un consumidor.
- Implementar y validar motor y fuentes de alternativas; representar un modo
  no implica que un proveedor lo soporte o que exista oferta disponible.
- Contrastar preferencias y alcance con FDC-124.

B3 no modifica el cálculo OSRM actual ni produce recomendaciones personalizadas.

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
