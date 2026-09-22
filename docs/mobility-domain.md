# Dominio de movilidad

Este paquete define datos y contratos independientes de Photon, OSRM, Google,
Supabase y la interfaz. En el baseline B5 `f2009b2`, Home consulta alternativas
vehiculares OSRM y muestra el `RouteResult` seleccionado manualmente; todavía
no utiliza un motor de recomendaciones. Ver [B4](route-alternatives.md).

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

`OsrmRoutingService.route` devuelve un `RouteResult`; `routeAlternatives`
devuelve la lista de candidatas que usa Home. Un consumidor futuro puede
envolver cada resultado con `RouteOption.fromRouteResult`, indicando `TransportMode.driving`
y `source: 'osrm'`, sin depender de clases OSRM dentro del dominio. El modelo
legado `GoogleRouteResult` permanece separado.

Tráfico y reportes no tienen proveedor activo. [B3](mobility-preferences.md)
captura modos localmente, compatibles con `MobilityContext.allowedModes`,
sin persistencia ni conexión con un consumidor desde Perfil. Esas preferencias
todavía no alimentan condiciones, razones o rutas. No se combinan opciones de
distintos modos. Falta definir e implementar una
estrategia real para comparar alternativas y explicar la elección.

**El dominio no constituye por sí mismo un motor inteligente.**
