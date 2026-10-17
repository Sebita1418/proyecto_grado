> Estado actual al cierre del 16/10/2026: función desplegada y consulta remota real aprobada. Véase [acta de sesión Flutter](../../../docs/evidence/fdc125/04-objetivo-3/tomtom-flutter-session-20261016/README.md) y [adaptación API sin Docker](../../../docs/evidence/fdc125/04-objetivo-3/tomtom-api-bundle-20261016/README.md). El texto de preparación inicial que sigue es histórico; no representa el estado remoto vigente.

# Tráfico: preparación local, sin despliegue

Estado: BLOCKED. El usuario confirmó que no dispone de API key. No se ha
consultado TomTom, aplicado SQL, contratado consumo ni desplegado esta función.

Contrato oficial: https://docs.tomtom.com/traffic-api/documentation/tomtom-maps/v1/traffic-flow/flow-segment-data
La matriz del proveedor incluye Colombia; no demuestra cobertura por calle en
Bucaramanga, Girón o Floridablanca. La muestra es un fragmento próximo, no toda
la ruta ni una identificación de carril o sentido. Flutter no modifica el tiempo
OSRM con estos datos. Confianza mínima local 0,8; antigüedad máxima 120 s;
desviación geométrica máxima 25 m: umbrales conservadores sin calibración física.

Antes de habilitar, con aprobación del responsable:

1. Verificar licencia y presupuesto TomTom. Configurar `TOMTOM_API_KEY` como
   secreto del servidor, nunca como dart-define ni archivo versionado.
2. Revisar y aplicar `supabase/traffic-quota.sql`. La configuración nace
   deshabilitada y con cero solicitudes. Autorizar explícitamente un techo diario
   en `traffic_quota_settings`; la cuota UTC compartida se consume atómicamente
   antes de cada solicitud y no se devuelve ante errores del proveedor.
3. Desplegar `traffic-flow` conservando JWT y los tres GeoJSON de `geo/`.
   Sus hashes deben coincidir con `assets/geo/`. Auth se vuelve a validar con
   `/auth/v1/user`; la clave de servicio solo llama el RPC reservado.
4. Validar en staging JWT inválido, cuota agotada, timeout, 429, polígonos,
   persistencia del contador y consultas autorizadas locales. El wrapper Deno y
   el SQL requieren prueba de integración remota; los tests Node solo cubren
   el handler con dependencias controladas.
5. Solo entonces construir con `--dart-define=TRAFFIC_PROXY_ENABLED=true`.
   El APK de esta intervención conserva el valor `false`: no consume la API.

Cliente: una coordenada central por geometría y como máximo tres alternativas
secuenciales; caché de 60 s, hasta 100 entradas. Servidor: caché efímera de 60 s,
100 entradas; cuota persistente agregada diaria. El caché no es almacenamiento
histórico ni sustituye la cuota compartida. No se registran URL con claves,
cabeceras ni cuerpos de error del proveedor. No se garantiza disponibilidad ni
protección frente a agotamiento deliberado de cuota por un usuario autenticado.
