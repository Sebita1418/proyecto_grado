# Experiencia map-first

Incremento basado en `3b699ef` de develop, tras integrar la baseline B8 por #36.

- Home conserva el mapa completo y servicios existentes. Header con inicial del
  perfil real, controles flotantes y panel inferior limitado al 48 % de altura;
  en escritorio el panel tiene ancho limitado. El contenido puede desplazarse.
- Planner compacto con destino principal, chips de modos y origen GPS/manual.
  Solo vehículo está habilitado. Se conservan Photon, Nominatim, OSRM, B6 y
  protección de solicitudes obsoletas; no cambia la política del motor B8.
- Resultado con métricas y extremos reales, etiquetas B7 de la alternativa
  seleccionada y explicación B8 en un sheet de ancho limitado. Anterior/siguiente o selector
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

## Completar la experiencia sobre `04c4c91`

El panel se puede minimizar y expandir conservando entradas, ruta y selección;
el FAB acompaña ese estado. Con poca altura disponible (incluido el teclado),
los controles se distribuyen horizontalmente y el planner limita su altura al
viewport disponible. El aviso de perfil se puede ocultar.

Las categorías del reporte forman una cuadrícula de dos columnas. Tras elegir
una ubicación manual se puede regresar al GPS conservando tipo y descripción.
Un borrador preparado aparece en el mapa con un marcador «Borrador no publicado»;
su detalle permite editarlo o descartarlo. No representa un incidente persistido
ni forma parte de un feed en vivo. La infraestructura de persistencia sigue
pendiente, pese al título del commit #37.
