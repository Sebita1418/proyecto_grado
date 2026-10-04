# Análisis de reportes próximos a alternativas

## Objetivo y fuentes

Conectar las alternativas geométricas y métricas de OSRM con la colección
de reportes activos que ya entrega `RoadIncidentController` desde Supabase.
Es análisis espacial y un motor de recomendación determinista con reglas
explicables, sin modelos predictivos. **OSRM no consume estos reportes**:
no se modifican su petición, geometría, duración ni distancia por un reporte.
No se calculan retrasos, velocidades ni tráfico a partir de categorías.

`RouteIncidentAnalysis` identifica la alternativa y conserva referencias a
los modelos de reporte existentes, distancia mínima aproximada, conteos,
categorías, presencia de cierre y momento de evaluación. Sus colecciones son
inmutables. No depende de Supabase ni realiza red.

## Algoritmo espacial

`RouteIncidentAnalyzer` proyecta cada segmento a un plano local centrado en
el reporte. Para coordenadas en radianes, x = R·cos(latitud del reporte)·Δlongitud
e y = R·Δlatitud, con radio terrestre medio R = 6 371 008,8 m. Normaliza la
diferencia de longitud a [-180°, 180°). Proyecta el origen sobre cada segmento
AB con t = clamp(−A·(B−A)/|B−A|², 0, 1), y obtiene la norma de A+t(B−A).
Conserva el mínimo sobre todos los segmentos, incluidos extremos; segmentos
de longitud cero se tratan como puntos. No compara solo contra vértices.

Umbral central: `RouteIncidentAnalyzer.proximityMeters = 125.0`, inclusivo.
Es una aproximación razonable para corredores urbanos, no una solución GIS
para trazados globales ni map matching de carriles. Coste O(alternativas ×
segmentos × reportes), sin llamadas externas. Se filtran estado no activo,
expiración al instante explícito de evaluación, coordenadas inválidas,
identidad vacía y fechas de expiración inconsistentes; se deduplica por id.

**Próximo significa cercanía geométrica**, no confirma que un incidente bloquee
la ruta, su carril, el sentido de circulación o su nivel vertical. Un cierre
se presenta como «Cierre vial reportado próximo al recorrido».

## Regla exacta de recomendación

Decisión técnica **provisional del prototipo**, no requisito institucional:

1. Conservar validación de opciones y preferencias; solo vehículo elegible.
2. Determinar referencia por menor duración OSRM, luego distancia y, en empate,
   orden original del proveedor.
3. Formar grupo comparable con duración ≤ 1,25 × duración de esa referencia
   **y** distancia ≤ 1,50 × distancia de esa misma referencia. La referencia
   siempre pertenece al grupo, incluso con métricas cero.
4. Si en ese grupo existe alguna alternativa sin cierre próximo, descartar de
   la competencia las que tienen cierres próximos. Si todas tienen cierre,
   mantenerlas para comparación; no afirmar ausencia de cierres.
5. Preferir el menor número de reportes próximos distintos. Todas las categorías
   cuentan una vez por reporte, sin pesos ficticios ni penalizaciones en minutos.
6. Desempatar por duración OSRM, distancia OSRM y orden del proveedor.

Las alternativas fuera del grupo **siguen disponibles y seleccionables**.
Si faltan análisis para alguna candidata, no se asume exposición cero: se
utiliza el criterio anterior de duración/distancia. En Home, una fuente aún
no disponible o con error desactiva la comparación por reportes y muestra
«Reportes no disponibles; comparación por duración y distancia».

La recomendación y la selección son distintas: ni el cálculo inicial ni una
actualización Realtime sustituyen una elección manual por la sugerencia.

## Realtime y navegación

Home pasa la colección del controlador existente al panel. Al reemplazarse
la colección por una publicación, un refresh Realtime o la purga de expirados,
se recomputan análisis y recomendación sobre las alternativas guardadas.
El selector abierto también recibe la actualización mediante un notifier.
Versiones de cálculo/evaluación descartan respuestas antiguas del motor.
No se consulta OSRM, se alteran preferencias ni se cambia la geometría elegida.

Navigation V2 mantiene GPS, maniobras, reroute y marcadores. El análisis mostrado
pertenece a las alternativas de planificación; no se impone un cambio de ruta
durante navegación ni se presenta ese análisis como el de una geometría nueva
obtenida por reroute. Los avisos existentes de navegación permanecen intactos.

## Interfaz y detalle

Cada alternativa mantiene sus métricas OSRM y muestra conteo/categorías o
«Sin reportes activos próximos». La seleccionada muestra el mismo estado.
«Por qué esta ruta» explica filtros y desempates. Tocar un estado con reportes
abre su lista de proximidades aproximadas y reutiliza el detalle de reporte.
Esa lista de detalle es una instantánea al abrirla; el selector sí se actualiza
en vivo. No se duplica el feed general ni se añaden tablas o políticas RLS.

## Límites y prueba manual

La colección actual está limitada a 100 reportes por el flujo existente;
ausencia en esa colección no garantiza ausencia en la vía. La precisión depende
del GPS, geometría, ubicación y veracidad del reporte. Calles paralelas, puentes
y sentidos opuestos pueden producir proximidad sin afectación. La expiración
visual sigue la purga existente (hasta aproximadamente un minuto); cada análisis
filtra con la hora real de evaluación. El detalle abierto conserva su snapshot.

Prueba para Sebastián:

1. Autenticarse con dos clientes. En A buscar una dirección/POI y calcular un
   viaje para el que OSRM devuelva al menos dos alternativas.
2. Abrir «Cambiar alternativa» y comparar tiempo, distancia y reportes. Elegir
   una alternativa manualmente; observar que selección y sugerencia se distinguen.
3. En B publicar un reporte (preferiblemente cierre) en un segmento exclusivo
   de una candidata, dentro de 125 m y separado más de 125 m de las otras.
4. Mantener abierto el selector en A: debe cambiar conteo/categoría sin consultar
   otra vez OSRM. La sugerencia cambiará si los límites comparables lo permiten;
   la selección y la línea elegida deben permanecer.
5. Consultar «Por qué esta ruta» y tocar el estado de reportes para ver distancia
   aproximada y detalle. Verificar que nunca se añaden minutos de retraso.
6. Publicar fuera del corredor y comprobar que no aumenta su conteo. Iniciar
   Navigation V2, recibir otro reporte, comprobar marcadores/maniobras/GPS y
   provocar un desvío controlado para verificar el reroute existente.

Los tests usan geometrías, HTTP/GPS y eventos controlados; no consultan Supabase
ni OSRM reales. La demostración real con dos clientes debe ejecutarse aparte.
