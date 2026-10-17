# traffic-flow: adaptación del bundle para despliegue API sin Docker

Fecha: 16 de octubre de 2026, America/Bogota. Rama conservada:
`feature/android-end-to-end-validation`.

**PASS local: 11 pruebas Node, cero fallos. Despliegue y consultas remotas:
NOT TESTED.** No se ha declarado éxito remoto ni consumido TomTom en este trabajo.
El usuario confirmó que `TOMTOM_API_KEY` existe en el servidor; no se leyó su valor.

## Cambio mínimo

- `index.ts`: sustituido exclusivamente el cargador `Deno.readTextFile` por
  `import { geometries } from './geometries.generated.ts'`.
- `supabase/config.toml`: retirada únicamente la entrada `static_files`.
  Se conserva `verify_jwt = true`.
- Nuevo `tools/bundle-traffic-geometries.mjs`: lee directamente los tres originales
  DANE de `assets/geo/` y genera un módulo TypeScript autocontenido, con exports
  compatibles con JavaScript. No hay lectura de archivos en runtime ni paquetes
  nuevos. El bundler puede seguir el import local sin assets estáticos externos.
- Nuevo `geometries.generated.ts`: conserva todas las geometrías y documenta
  hashes de originales y geometrías. No simplifica, redondea ni reproyecta.
  La representación numérica es exactamente la que obtenía el cargador anterior
  con `JSON.parse`. La comparación profunda incluye todos los números y anillos.

Los GeoJSON originales y sus copias anteriores de `geo/` permanecen intactos.
Los archivos preservados en `index.before.txt` y `config.before.txt` permiten
revisar el cambio del cargador. No contienen secretos.

## Verificación ejecutada

```powershell
node tools/bundle-traffic-geometries.mjs
node tools/bundle-traffic-geometries.mjs --check
node --test tools/bundle-traffic-geometries.test.mjs supabase/functions/traffic-flow/handler.test.mjs
git diff --check
```

Node v22.21.0. Resultado: **11 PASS, 0 FAIL, 0 SKIP**, en aproximadamente 1,53 s.
`node-tests.log`, `tests-command.json`, `generation-check.log` y
`diff-command.json` conservan los resultados originales. No se ejecutó Flutter
porque no se modificó; no se generó APK.

Las pruebas importan el contenido real del módulo generado y verifican:

1. Regeneración determinista e igualdad profunda con las tres geometrías.
2. Hashes de originales, coordenadas y copias del servidor, por municipio.
3. Puntos conocidos interiores de Bucaramanga, Girón y Floridablanca; exclusión
   de Piedecuesta y Bogotá, con los mismos resultados que el cargador anterior.
4. Cuadrícula de 21 × 21 por geometría, puntos exteriores y muestras de anillos
   con perturbaciones de ±1e-8 grados: resultados anteriores/nuevos idénticos.
5. Imports locales, ausencia de lecturas runtime/static_files y JWT conservado.
6. Regresiones del handler: autenticación, configuración, cuota, territorio,
   caché, errores sin exposición de secretos y polígonos con agujeros.

`equivalence.json` prueba **118 archivos protegidos sin cambios**, incluyendo
todo `lib/`, lock, los tres APK previos, originales DANE, copias GeoJSON,
handler y SQL. El bloque de `index.ts` desde las variables de servidor hasta
el final se conserva idéntico: Auth, secreto y llamada a cuota no cambiaron.

SHA-256 del módulo de 595.550 bytes:
`615b82bd90da87a9cf83fe68d1994b7bed5ad78a378f25cadd58e2bca9a3de41`.

La ejecución directa del módulo generado fue validada por Node CLI en las
pruebas. Una inspección adicional desde el REPL rechazó su import `data:` por
restricción de esa herramienta; no fue un fallo del módulo y no alteró archivos.
No se confunde la validación Node con una prueba del runtime remoto Deno.

## Comandos exactos de PowerShell: sin Docker

La referencia pública procede de `lib/config/supabase_config.dart`.
Confirmar que corresponde al proyecto donde se creó el secreto antes de ejecutar.
No es necesario `supabase init`, `start` ni `link`: `--project-ref` identifica
explícitamente el destino y evita modificar la configuración existente.

```powershell
Set-Location 'C:\Proyectos\transporte_inteligente'

node tools/bundle-traffic-geometries.mjs --check
if ($LASTEXITCODE -ne 0) { throw 'El módulo no coincide con los originales DANE.' }

node --test tools/bundle-traffic-geometries.test.mjs supabase/functions/traffic-flow/handler.test.mjs
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas del bundle.' }

npx supabase login
if ($LASTEXITCODE -ne 0) { throw 'No se completó la autenticación de Supabase.' }

npx supabase functions deploy traffic-flow --project-ref zdjhqcarmmdgdfzuxhgv --use-api
if ($LASTEXITCODE -ne 0) { throw 'Falló el despliegue por API.' }

npx supabase functions list --project-ref zdjhqcarmmdgdfzuxhgv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el estado remoto.' }
```

`npx` puede solicitar descargar la CLI; no modifica las dependencias Flutter.
El login debe completarse en el navegador de la persona autorizada. No pegar
tokens ni secretos en el chat. No usar `--no-verify-jwt`.
Supabase documenta explícitamente [el despliegue --use-api sin Docker](https://supabase.com/docs/guides/functions/quickstart#step-6-deploy-to-production).

## Requisito SQL y comprobación remota pendiente

Desplegar la función **no aplica** `supabase/traffic-quota.sql`. El usuario
confirmó que todavía falta aplicarlo: debe ejecutarse el archivo existente en
el SQL Editor del proyecto, sin cambiar su diseño, y autorizar después una
cuota diaria pequeña. El valor inicial es deshabilitado/cero; se conserva para
evitar consumo no autorizado. No se ejecutó ni se habilitó SQL en este trabajo.

Después del despliegue y de configurar la cuota, probar con una sesión real
autenticada y vigente de Supabase Auth (la sesión CLI administrativa no sustituye
al JWT de usuario del endpoint): una llamada por municipio, registrar HTTP,
`queriedAt`, `queryCoordinate`, `currentSpeed`, `freeFlowSpeed`, tiempos y
`confidence`, sin guardar cabeceras ni tokens. Las pruebas sin credenciales
deben ser rechazadas y los puntos externos no deben consumir TomTom.

Un resultado 429 `QUOTA_OR_CONFIGURATION` no demuestra un fallo de empaquetado:
indica cuota/RPC/configuración; 401 requiere revisar autenticación y no desactivar
JWT. No afirmar éxito hasta recibir y validar una respuesta remota real.

La adaptación no modifica la política de recomendaciones ni habilita Flutter.
El tráfico sigue siendo evidencia de fragmento; este cambio de empaquetado no
demuestra influencia sobre el ranking o un ETA. Sin commit, push ni publicación.
