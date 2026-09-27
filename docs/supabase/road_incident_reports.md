# Reportes viales V1

1. En Supabase SQL Editor ejecutar el bloque `begin;` → `commit;` de
   `road_incident_reports.sql`. Crea únicamente `public.reportes_viales`.
   Si ya existe, el script falla sin reemplazarla: comprobar antes su esquema.
2. Ejecutar el **BLOQUE 2** del mismo archivo para agregar la tabla a
   `supabase_realtime`. Este bloque sí puede repetirse.
3. Iniciar sesión y actualizar reportes en la app. Una consulta exitosa habilita
   «Publicar reporte». Si falta backend, se conserva el borrador local.

La FK apunta a `auth.users(id)`, la identidad usada por `PerfilService` para
`perfiles.id`; no se cambia la tabla de perfiles. RLS permite leer únicamente
activos no expirados y crear con `usuario_id = auth.uid()`. No hay permisos
UPDATE/DELETE para clientes. Las fechas, estado e ID los define el servidor;
el cliente solo puede insertar categoría, coordenadas, descripción y autor.

La duración de **seis horas** es una decisión provisional del prototipo,
no un requisito institucional. RLS filtra con reloj del servidor y el cliente
retira expirados cada minuto sin consultas HTTP ni cron de borrado.

Se consultan como máximo los 100 activos más recientes. Realtime invalida esa
lista con debounce de 350 ms; se vuelve a consultar bajo RLS y se deduplica por
ID. Se escuchan INSERT/UPDATE/DELETE y reconexiones. La actualización manual
permanece disponible si falla Realtime. Un UPDATE administrativo que vuelva
invisible la fila bajo RLS puede no generar evento para el lector; usar refresh
para esos cambios. V1 no incluye cancelación por el usuario.

Prueba: A publica; B, con otra sesión y mapa abierto, recibe el marcador o usa
Actualizar reportes. B ve tipo, descripción, fecha y estado, sin identidad del
autor en la UI. Repetir durante Navigation Mode y comprobar que GPS continúa.
Los reportes no modifican OSRM ni la recomendación.

La suite usa HTTP simulado y streams controlados. SQL/RLS y comunicación real
entre dos clientes requieren esta prueba remota; no están certificados por los
tests Dart. No se ha ejecutado el SQL remotamente.

Referencias: [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
y [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes).
