# Experiencia map-first

Integración de la UX sobre `04c4c91` con navegación #38 y reportes realtime #39.

- Home mantiene el mapa OSM, header flotante, perfil real y aviso descartable.
- Planner y resultado se pueden minimizar sin perder entradas ni selección.
  El panel limita su altura al viewport disponible y los controles se adaptan
  al teclado. Los sheets tienen ancho limitado en escritorio.
- OSRM, B6, comparación B7 y motor B8 conservan su arquitectura. La explicación
  real se consulta en un sheet secundario; cambiar alternativa no consulta OSRM.
- Navegación usa NavigationSession, GPS y progreso sobre la geometría existente.
  La estimación restante es proporcional a OSRM; no es tráfico ni ETA dinámico.
  Al finalizar se recupera el resultado y la alternativa seleccionada.
- Reportar usa el dominio, servicio y controller de #39. Categorías en dos
  columnas, descripción de hasta 200 caracteres y ubicación GPS o manual.
  Confirmar/cancelar la ubicación conserva categoría y descripción. Se puede
  regresar a GPS, editar o descartar un borrador sin publicarlo.
- Publicación espera la respuesta real y conserva el borrador si falla. El
  controller identifica reportes por id y evita duplicados entre envío y stream.
  Los marcadores de borrador y de reporte publicado usan el mismo componente
  con estados explícitos. Sus detalles no exponen identificadores de usuario.
- Drawer conserva rutas, perfil y autenticación existentes. Inicio solo cierra
  el menú; no destruye la ruta, el borrador ni la navegación.

La persistencia depende del contrato Supabase de #39 y sus políticas desplegadas.
No se cambia esquema ni se fabrican reportes cuando el backend no está disponible.
Las pruebas cubren 320/390/768/1440 px, texto 150 %, teclado, navegación,
ubicación manual, errores de publicación y actualizaciones sin duplicados.
