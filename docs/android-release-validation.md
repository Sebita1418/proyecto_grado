# Validación Android para entrega académica

Fecha: 14 de octubre de 2026, America/Bogota. Proyecto: Transporte Inteligente.

## Alcance de entrega

Rama feature/android-end-to-end-validation; commit base 226f1a4fb04fcc8b5bc8a2aed4e7e4a550b71fa4 más cambios locales conservados. APK release solicitado para demostración académica. La configuración release usa signingConfigs.debug: **no es firma de producción**. Application ID com.example.transporte_inteligente, versión 1.0.0, versionCode 20261014 por argumentos de compilación; pubspec.yaml conserva 1.0.0+1. No se modifica configuración de firma, dependencias ni credenciales. Se verificaron hashes intactos de pubspec.lock, pubspec.yaml, AndroidManifest.xml y build.gradle.kts.

Paquete fuera de build: deliveries/2026-10-14-android-academic/. La ficha version.json, manifiesto de fuentes y SHA-256 del APK identifican el artefacto. El commit base por sí solo no reproduce los cambios locales: conservar este workspace y comparar evidence/source-files.sha256. No se promete reproducibilidad binaria idéntica de una compilación futura.

## Matriz de validación

| Control | Estado | Evidencia |
|---|---|---|
| Rama y cambios anteriores | PASS | Rama esperada, working tree modificado, sin descarte ni cambio de rama |
| Análisis | PASS | flutter analyze --no-pub: No issues found, 99,0 s |
| Pruebas automáticas | PASS | flutter test --no-pub: 742 aprobadas, 1 min 16 s; incluye OAuth, territorio, búsqueda y navegación |
| Diff | PASS | git diff --check: código 0, también tras documentación |
| Build release | PASS | assembleRelease 322,8 s; Built app-release.apk; código 0 |
| Firma, SHA-256 y contenedor APK | PASS | apksigner verify código 0, v2; SHA-256 del paquete coincide con APK instalado; ZIP leído para comprobar assets |
| Assets de tres municipios | PASS | Tres entradas assets/flutter_assets/assets/geo/ con tamaños y hashes idénticos al workspace |
| Instalación física del APK exacto | PASS | adb install -r de la copia de entrega: Success; SHA-256 instalado coincide; versionCode=20261014 |
| Apertura física / interfaz visible | PASS | Arranque COLD, Status ok, PID 14570, MainActivity en primer plano; captura s22-launch.png observada con Home y mapa |
| Google OAuth real con cuenta del usuario | NOT TESTED | Home restauró sesión previa; no acredita login nuevo. Usuario respondió «Lo probaré ahora»; resultado todavía pendiente |
| GPS y rutas reales | NOT TESTED | Se solicitó prueba manual; usuario probará ahora, sin resultado concreto. Captura inicial muestra ubicación buscando; no se mide navegación física |
| Placas exactas de direcciones auditadas | NOT TESTED | Sin coordenadas de referencia verificadas; limitación documentada |
| Distribución de producción | NOT TESTED | Fuera de alcance: firma debug existente y applicationId com.example |

PASS indica un control ejecutado con evidencia favorable. FAIL indica un control ejecutado con resultado negativo: no queda ningún fallo pendiente en los controles obligatorios de entrega. NOT TESTED indica una interacción o condición no observada; la firma de producción continúa fuera de alcance.

## Artefacto final y firma

APK: deliveries/2026-10-14-android-academic/transporte-inteligente-1.0.0-20261014-release-debug-signed.apk

Tamaño: **60.331.191 bytes (57,536 MiB)**. SHA-256:

    040768c25ab2075125957dafe47939f82e57f4299c0a8a78b48b5ef4236fc6c3

Firma verificada: C=US, O=Android, CN=Android Debug; APK Signature Scheme v2. Certificado SHA-256:

    27b98872756c1a1e6dea44defae811127be4dbf7f6e1c666dab9a8757c9d5a85

Modo de compilación **release**, certificado **debug**: son conceptos diferentes. El APK instalado no tiene flag DEBUGGABLE; el certificado no se convierte en firma de producción por compilar release. minSdk 24, targetSdk/compileSdk 36; el S22 API35 es compatible. No se necesitó usar fallback debug. Su firma previa se verificó y el archivo build/app/outputs/flutter-apk/app-debug.apk se conserva.

Se instaló la copia externa a build, no un APK anterior. En el S22, adb shell sha256sum sobre base.apk devolvió exactamente el hash anterior; dumpsys confirmó versión 1.0.0, código 20261014, actualización 14/10/2026 18:36:07. Arranque observado a las 18:36: Home, mapa y controles visibles; sesión previa conservada. Logcat del PID inicial no mostró errores AndroidRuntime en esa ventana breve; esto no es una prueba prolongada de estabilidad ni una verificación completa de servicios.

La verificación de assets usa evidence/verify-apk.ps1 con PowerShell/.NET, sin instalar dependencias. Se abre el ZIP y se comparan hash y longitud de cada asset con los valores tomados del workspace. El lector Python no estaba disponible; se sustituyó por este verificador y el control final pasó.

## Configuración inspeccionada

Android/app/build.gradle.kts mantiene Java 17, namespace/applicationId com.example.transporte_inteligente y valores SDK de Flutter. Manifest principal conserva INTERNET y ACCESS_FINE_LOCATION, actividad MAIN/LAUNCHER singleTop y callback VIEW/DEFAULT/BROWSABLE transporteinteligente://login-callback/. flutter_deeplinking_enabled=false deja el callback al SDK Supabase/app_links. Inicialización Supabase y credencial pública existentes no se cambiaron; no se incluyen secretos o keystores en la entrega. Registrar exactamente transporteinteligente://login-callback/ en Redirect URLs de Supabase; no se verificó el Dashboard desde aquí.

Los assets declarados son assets/geo/bucaramanga-mgn2024.geojson, giron-mgn2024.geojson y floridablanca-mgn2024.geojson. Sus archivos DANE MGN 2024 se conservaron. Cobertura operativa de extremos: 68001, 68307, 68276; Piedecuesta sigue excluida. Attribution DANE/OSM conservada.

El flujo Home/Rutas usa OSRM, no necesita GOOGLE_ROUTES_API_KEY. Esa variable existe únicamente en el módulo Google Routes heredado; no se suministró una clave nueva. La configuración Supabase está en el código existente; se omitió el valor de la clave de las inspecciones y no se exporta como secreto. Los servicios externos requieren Internet; una compilación correcta no acredita disponibilidad, autorización del callback en Dashboard ni calidad de placas.

## Comandos y entorno

Flutter 3.47.7 stable, revisión abaf9c5237; Dart 3.13.5. Android SDK C:\Android\sdk; herramientas build-tools 36.0.0. Samsung Galaxy S22 SM-S901U, serial R3CT30HX60V, Android 15/API 35.

    git branch --show-current
    git status --short
    git diff --stat
    flutter analyze --no-pub
    flutter test --no-pub
    git diff --check
    flutter build apk --release --no-pub --build-name=1.0.0 --build-number=20261014

La compilación emitió avisos de APIs Java obsoletas, sin impedir assembleRelease: BUILD_EXIT=0. Logs completos se conservan en el paquete evidence/. No se modificó el entorno por esos avisos.

Comprobaciones del artefacto y dispositivo:

    apksigner verify --verbose --print-certs <APK de entrega>
    aapt2 dump badging <APK de entrega>
    aapt2 dump xmltree --file AndroidManifest.xml <APK de entrega>
    powershell -File deliveries/2026-10-14-android-academic/evidence/verify-apk.ps1
    adb -s R3CT30HX60V install -r <APK de entrega>
    adb -s R3CT30HX60V shell am force-stop com.example.transporte_inteligente
    adb -s R3CT30HX60V shell am start -W -n com.example.transporte_inteligente/.MainActivity
    adb -s R3CT30HX60V shell dumpsys package com.example.transporte_inteligente
    adb -s R3CT30HX60V shell pm path com.example.transporte_inteligente
    adb -s R3CT30HX60V shell sha256sum <ruta base.apk instalada>

Captura observada: evidence/s22-launch.png. Las rutas exactas y salidas están en los logs, sin keystores o claves secretas.

## Límites y decisiones

La firma debug sirve para instalación de demostración, no para declarar una distribución de producción. Producción requiere autorización para applicationId definitivo, firma protegida y política de servicios públicos. Las placas exactas continúan limitadas por las respuestas de los proveedores; [auditoría de direcciones](address-and-navigation-audit.md) contiene 18 consultas reales y alternativas. Cámara 2D, sin 3D ni tráfico en vivo. Mantener pruebas físicas como NOT TESTED hasta observarlas; no sustituirlas por fixtures.

Para instalar y validar seguir INSTALACION.md en el paquete. El usuario selecciona personalmente su cuenta Google y concede permisos GPS. Ante conflicto de firma no desinstalar sin revisar pérdida de datos. Como pasajero o en prueba supervisada, confirmar destino, ruta, seguimiento, giro, detenido y recentrado. Registrar referencias reales; no manipular el teléfono al conducir.

## Seguridad Git

Se conserva el estado previo de pubspec.lock (ya modificado antes de esta fase), hash SHA-256 cf0ea1843a277fb73974690d7759d01fda55f02983292e6562b68b2691a443c3. Stash original cc2b34eb080858401908a211262d299111bfd4fe, sin aplicar ni borrar. No reset, clean, restore, commit, push o PR. Únicos archivos nuevos de esta fase: este documento y el paquete deliveries/; los logs de comandos sirven como evidencia de validación.


## Corte posterior: intervención objetivo 3, 16 de octubre de 2026

El APK 1.0.2+2026101601 corresponde a código funcional posterior al corte de este documento. Su acta y resultados están en [la verificación final del objetivo 3](evidence/fdc125/04-objetivo-3/objective-3-final-verification.md) y `deliveries/objective-3-intervention-20261016/version.json`. Las observaciones y videos anteriores conservan su alcance original; no validan esta versión. Tráfico externo deshabilitado por ausencia de clave.
