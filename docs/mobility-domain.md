# Dominio de movilidad

Responsable actual: Sebastián. Baseline `189cd0a1a208b45f03a05f104ab61716db7ee38a`, con #31, #32 y #33 integrados; 206 pruebas en ese baseline.

El dominio define datos y contratos independientes de Photon, OSRM, Google, Supabase y la interfaz. Desde #33 Home utiliza un motor vehicular productivo, determinista y explicable. Véase [modelo de recomendación](recommendation-model.md).

## Modelos y relaciones

- `TransportMode` representa driving, walking, cycling y publicTransport; representarlos no equivale a disponer de routing para todos ellos.
- `MobilityConditions` conserva condiciones opcionales; `null` significa desconocido, nunca congestión o incidentes cero. No hay proveedor activo de condiciones y la política vehicular no las usa.
- `RouteOption` añade identidad, modo y fuente a `RouteResult` por composición, con geometría inmutable y validada. No se duplica el modelo de ruta.
- `MobilityContext` reúne extremos, modos permitidos y momento del cálculo. Los modos proceden del almacenamiento local o del default driving explícito cuando no hay modos guardados.
- `MobilityRecommendation` contiene opción sugerida, otras elegibles, razones estructuradas y momento de evaluación. No afirma optimalidad global.
- `VehicleRecommendationEngine` implementa `MobilityRecommendationEngine`: menor duración estimada, luego menor distancia y, ante empate completo, orden del proveedor. No altera la lista ni inventa pesos, tráfico o preferencias personales de tiempo/distancia.

## Integración productiva

Home → MapSearchPanel → OSRM `routeAlternatives` → lectura de preferencias → adaptación a `RouteOption` → contexto → motor → sugerencia inicial → mapa, tarjeta y detalles. `route()` conserva su contrato de una ruta; el modelo Google legado sigue separado.

Con driving guardado son elegibles las candidatas vehiculares. Sin modos guardados se comunica el flujo vehicular por defecto, sin atribuirlo al usuario. Con modos guardados sin driving no se selecciona una ruta ni se simulan otros medios. Un fallo de lectura se informa y no se interpreta como ausencia de preferencias.

El resumen distingue «Ruta sugerida» de «Selección manual». La tarjeta conserva «Ruta seleccionada». Elegir otra alternativa no consulta proveedores ni vuelve a ejecutar el motor; mapa, tarjeta y detalles reflejan la misma candidata. OSRM puede devolver una sola alternativa.

## Evidencia y límites

[Pruebas del motor](../test/mobility/vehicle_recommendation_engine_test.dart), [resumen](../test/widgets/mobility_recommendation_summary_test.dart) y [flujo Home](../test/screens/home/route_flow_test.dart) cubren reglas, elegibilidad, explicación, selección manual e invalidación. [Preferencias](mobility-preferences.md) documenta persistencia por instalación, no por cuenta ni Supabase.

RF-MOB-01 es PARCIAL: hay recomendación vehicular explicable, pero faltan personalización completa, evaluación con usuarios y contraste FDC. RF-MOB-02 sigue PENDIENTE: no hay horarios ni comparación productiva entre medios. No es IA, ruta óptima ni tráfico en tiempo real. La regla es técnica provisional, sin acreditación académica definitiva. La aceptación manual está [pendiente de ejecución](demo-acceptance.md).
