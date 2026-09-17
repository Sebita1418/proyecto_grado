# Dominio de movilidad

Este paquete define datos y contratos independientes de Photon, OSRM, Google,
Supabase y la interfaz. El flujo actual de Home sigue calculando una ruta
vehicular con OSRM y mostrando su `RouteResult`; este incremento no lo cambia.

## Modelos y relaciones

- `TransportMode` expresa driving, walking, cycling y publicTransport sin
  convertirlos en perfiles de una API.
- `MobilityConditions` conserva congestión, cantidad de incidentes relevantes,
  retraso estimado y momento de evaluación cuando esos datos existen. `null`
  significa desconocido; nunca se interpreta como congestión o incidentes cero.
- `RouteOption` añade identidad, modo, condiciones y fuente opcional a un
  `RouteResult`. Usa sus puntos, extremos, distancia y duración por composición,
  con una copia inmutable de la geometría. La fábrica valida valores finitos,
  no negativos, coordenadas válidas y al menos dos puntos.
- `MobilityContext` reúne extremos, modos permitidos, momento de consulta y
  condiciones generales disponibles. No guarda preferencias inventadas; cuando
  existan requisitos concretos se puede incorporar un modelo de preferencias.
- `MobilityRecommendation` representa una opción elegida, alternativas
  diferentes, razones con categoría y explicación, y momento de evaluación.
  No afirma que la opción sea óptima. El contrato
  `MobilityRecommendationEngine` acepta contexto y opciones; no tiene
  implementación todavía.

## Integración actual y pendientes

`OsrmRoutingService` devuelve un `RouteResult`. Un consumidor futuro puede
envolverlo con `RouteOption.fromRouteResult`, indicando `TransportMode.driving`
y `source: 'osrm'`, sin depender de clases OSRM dentro del dominio. El modelo
legado `GoogleRouteResult` permanece separado.

Tráfico, reportes y preferencias podrán alimentar condiciones y razones cuando
existan fuentes y reglas verificables. Hoy no se consultan esas fuentes ni se
combinan opciones de distintos modos. Falta definir e implementar una
estrategia real para comparar alternativas y explicar la elección.

**El dominio no constituye por sí mismo un motor inteligente.**
