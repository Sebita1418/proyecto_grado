# Sistema visual de movilidad

## Principios

- El mapa ocupa el fondo completo y mantiene controles flotantes compactos.
- El panel prioriza destino, momento de salida, medios y acción principal.
- Las superficies usan blanco, azul profundo y grises claros, con bordes suaves y radios compartidos.
- La información depende del estado real de routing, preferencias, reportes e instrucciones de navegación.
- Los estados combinan icono y texto; el color solo refuerza el mensaje.

## Componentes y tokens

`MobilityTheme` concentra el `ColorScheme`, el fondo, el estilo de campos, botones y hojas. `MobilityDesign` aporta espaciado, dimensiones táctiles y radios pequeños y reutilizables.

Home reutiliza `NavigationHeader`, `MapFloatingControls` y `MapSearchPanel`. El panel compone `DepartureTimeSelector`, `TravelModeSelector`, `MobilityRecommendationSummary`, `RouteResultCard` y `RouteAlternativesSelector`. Los reportes siguen usando `ReportIncidentSheet`; Navigation V2 mantiene sus tarjetas de maniobra y estado.

## Adaptación

La hoja del planificador conserva un ancho máximo en escritorio y scroll interno. Los modos se disponen con `Wrap`; los campos y botones ocupan el ancho disponible. Los controles flotantes mantienen objetivos táctiles de 48 px. Los tests existentes de Home, reporte, navegación y panel cubren tamaños móviles, tablet y escritorio, además de texto ampliado.

## Figma y datos reales

Figma orienta jerarquía, color, superficies y densidad visual. Flutter conserva los cálculos y datos productivos. Valores ilustrativos del prototipo —por ejemplo, duraciones y distancias de ejemplo, confianza, nombres de calles, congestión, incidentes o ETA— no se codifican como resultados. Duración, distancia, geometría, recomendación y explicaciones proceden del routing y `RouteInsight` disponibles.

Vehículo es el único medio con routing implementado. A pie y Bicicleta no muestran rutas ficticias; Transporte público indica que sus datos no están integrados. La salida programada usa selectores reales de fecha y hora, pero no tiene evidencia temporal para predecir condiciones futuras. Una ruta ya calculada queda identificada como referencia de Ahora y no puede iniciarse mientras se mantenga la hora futura.

## Alcance OE4

El rediseño avanza OE4 al hacer más clara la consulta del mapa y el acceso a recomendaciones existentes. No se declara OE4 validado por completo: las pruebas formales de usabilidad se realizarán posteriormente. Tampoco se completa OE3; faltan fuentes temporales verificables y routing productivo para los demás medios.
