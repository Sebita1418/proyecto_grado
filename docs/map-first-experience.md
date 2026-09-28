# Experiencia map-first

Actualización: la publicación persistente y Realtime se implementan en
[Reportes viales V1](supabase/road_incident_reports.md). Requieren ejecutar el
SQL indicado allí; el borrador local sigue disponible si el backend no responde.
Las secciones siguientes describen el incremento original #37.

Incremento basado en `3b699ef` de develop, tras integrar la baseline B8 por #36.

- Home conserva el mapa completo y servicios existentes. Header con inicial del
  perfil real, controles flotantes y panel inferior limitado al 48 % de altura;
  en escritorio el panel tiene ancho limitado. El contenido puede desplazarse.
- Planner compacto con destino principal, chips de modos y origen GPS/manual.
  Solo vehículo está habilitado. Se conservan Photon, Nominatim, OSRM, B6 y
  protección de solicitudes obsoletas; no cambia la política del motor B8.
- Resultado con métricas y extremos reales, etiquetas B7 de la alternativa
  seleccionada y explicación B8 expandible. Anterior/siguiente o selector
  actualizan la misma ruta sin nueva consulta. Los detalles siguen en un sheet.
- Capas permite mostrar/ocultar únicamente el marcador GPS y la ruta calculada.
  El mapa base sigue siendo OSM; no hay capas de tráfico ni proveedores nuevos.
- Drawer conserva destinos y autenticación existentes, perfil real y selección
  explícita. «Reportes de la vía» abre el borrador, no un feed de reportes.

## Reportar novedad

El modelo existente `IncidentReportDraft` conserva categoría, coordenadas,
descripción de hasta 200 caracteres y procedencia manual de la ubicación.
Se permite un borrador incompleto; preparar requiere categoría y coordenadas.
El estado permanece en Home al cerrar/reabrir el sheet, solo durante esa sesión
de pantalla. No es persistencia en disco ni por cuenta.

«Cambiar ubicación» abre el mapa de selección con la geometría de la ruta
vigente como contexto. Tocar coloca/mueve un marcador de borrador distinto.
Confirmar devuelve la coordenada; cancelar o volver conserva la anterior.
No se cambia la ruta, no se llama a OSRM ni se escriben preferencias. El mapa de
selección no ajusta automáticamente la cámara al mover el marcador.

No se encontró servicio ni repositorio productivo de novedades. La acción se
llama «Preparar reporte» y comunica «Envío de reportes pendiente de habilitación».
No se modificó Supabase, autenticación, administración ni legacy Google Maps.

## Pruebas y continuación

Cobertura específica de ruta + reporte + cancelación + reapertura a
320/390/768/1440 px con texto 150 %, selección mediante tap real sin GPS,
capas, perfil/Drawer, teclado y límite de descripción. Se conservan los tests
de B6/B7/B8, invalidación, errores y selección manual sin consultas adicionales.
La validación automatizada no certifica disponibilidad de proveedores ni GPS
en dispositivo. Toolchains nativos siguen pendientes en este entorno.

Siguiente incremento: persistencia real de novedades con contrato de datos,
autorización y políticas RLS acordadas; después, listado de reportes reales.
No presentar el borrador como publicado antes de esa integración.

## Vista previa sobre el mapa

Preparar el reporte muestra un único marcador de borrador con el icono de la
categoría elegida. Tocarlo abre el detalle con la descripción disponible y el
estado «Borrador sin publicar». No se inventan fecha, autor ni reportes remotos.
La vista previa no interviene en el ajuste de cámara y se pierde al salir de
Home. El GPS usa un halo azul sin orientación inventada. Reportes publicados,
persistencia Supabase y realtime siguen pendientes del contrato de backend.

El panel de navegación se puede minimizar sin finalizar la sesión. La ruta minimizada conserva distancia y duración. La lista de reportes permite filtrar categorías localmente, muestra fecha real y mantiene una única suscripción al seleccionar una novedad y regresar al mapa.
