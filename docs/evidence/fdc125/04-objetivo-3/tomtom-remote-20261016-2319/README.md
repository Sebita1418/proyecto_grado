# Verificación remota TomTom: detenida por falta de sesión de usuario

Fecha local: 16 de octubre de 2026, America/Bogota. Proyecto
`zdjhqcarmmdgdfzuxhgv`. El día de cuota es UTC, por lo que puede figurar
2026-10-17 en las respuestas conservadas.

**PASS remoto:** CLI autenticada, proyecto accesible y consulta SQL real vía
Management API. `traffic_quota_settings`: `enabled=true`, `daily_limit=10`;
`traffic_quota_usage` del día UTC: `requests_today=0` en la lectura inicial.
El resultado de la lectura conservada está en `quota-observed.json`; salida
original y comando sin secretos en `quota-read.log` y `command.json`.
No se modificó configuración ni contador.

**BLOCKED:** este proceso no dispone de un JWT vigente de usuario de Supabase
Auth para el proyecto. El login administrativo de `npx supabase login` habilita
Management API, pero no identifica un usuario ante `/auth/v1/user`, que es la
validación exigida por `traffic-flow`. No se intenta sustituirlo con la clave
anon, service_role ni un token de administración; tampoco crear o suplantar un
usuario para conseguir una sesión. No se extrajeron credenciales del teléfono.

Se respetó la instrucción de detenerse ante el bloqueo: **cero solicitudes
TomTom**, sin respuesta de tráfico, velocidades, confianza o latencia observadas.
Invocación autenticada, incremento de cuota y restricciones remotas de Auth:
**NOT TESTED**. Las pruebas locales previas no sustituyen estas comprobaciones.
El despliegue exitoso fue informado por el usuario; no se convierte aquí en una
prueba remota funcional aprobada.

Para continuar, disponer de una sesión real vigente de Supabase Auth en el
entorno de ejecución; por ejemplo, configurar `SUPABASE_USER_JWT` únicamente en
la memoria de la sesión local autorizada, sin pegarlo en el chat, archivos de
evidencia, comandos versionados ni registros. No hace falta cambiar TomTom ni
la cuota ya verificada. Con esa sesión se debe leer contador, hacer una llamada
válida y verificar respuesta/calidad y contador después; después comprobar el
rechazo sin autenticación, sin guardar cabeceras.

El histórico de siniestros y las respuestas OSRM conservadas son evidencia
distinta y no se presentan como tráfico TomTom. El decorador actual añade la
observación y su calidad a la explicación, pero no reordena alternativas ni
modifica tiempos OSRM con una muestra de fragmento de sentido no confirmado.

Para habilitar consultas en Android sí hará falta **otro APK**, conservando los
anteriores, con `--dart-define=TRAFFIC_PROXY_ENABLED=true`. No se compiló aquí.
Mínimos previos: una respuesta remota autenticada válida; cuota incremental y
rechazo sin Auth; geocerca exterior; errores/timeout/429 sin datos inventados;
regresiones de geometrías y adaptador; identificación de versión/firma/SHA;
prueba física de cálculo, explicación y degradación sin tráfico. Si se pretende
afirmar influencia en el ranking, hace falta implementar y validar esa política
con correspondencia espacial y direccional suficiente: activar el flag solo
habilita la consulta, no demuestra esa capacidad.

Únicamente se añadieron evidencias de este intento. Flutter, función, SQL, APK,
dependencias y credenciales no se modificaron. Sin publicación GitHub.
