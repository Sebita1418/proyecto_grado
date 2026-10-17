# Google OAuth: retorno Android

Corrección del 14 de octubre de 2026 en `feature/android-end-to-end-validation`,
base `226f1a4`.

## Causa y cambio

Android enviaba `redirectTo=null`; Supabase utilizaba la Site URL predeterminada,
que en este proyecto llevaba a `http://localhost:3000/?code=...`. Además faltaba
el filtro Android capaz de abrir el callback. No había otro esquema nativo
configurado; el esquema diferente presente en un test era solo un valor simulado.

`AuthRedirect` conserva `Uri.base.origin` en web y selecciona únicamente en
Android **`transporteinteligente://login-callback/`**. Las otras plataformas
nativas conservan su comportamiento anterior. El servicio Google existente
recibe `redirectTo` sin modificar su contrato.

MainActivity conserva MAIN/LAUNCHER y singleTop, incorpora VIEW/DEFAULT/BROWSABLE
para esquema `transporteinteligente` y host `login-callback`, y desactiva
`flutter_deeplinking_enabled`. Así Supabase Flutter/app_links es el único
manejador de callback; no se agregó otro listener de enlaces ni otro plugin.

La inicialización existente en `main.dart` ya usa las opciones predeterminadas
del SDK: PKCE, recepción automática de enlaces y persistencia de sesión. La
versión instalada inspeccionada fue supabase_flutter 2.18.2. El SDK recibe el
código, lo intercambia por una sesión y emite el estado de autenticación. Login
solo valida perfil/navega con una sesión, vía signedIn, initialSession o sesión
restaurada al montar la pantalla. El resultado booleano de abrir OAuth nunca
autoriza navegación. Se manejan también errores asíncronos del stream de auth.

## Intervención manual en Supabase

En **Authentication → URL Configuration → Redirect URLs**, agregar y guardar:

```text
transporteinteligente://login-callback/
```

No modificar Site URL, credenciales Google ni secretos. El usuario indicó que
lo añadirá al panel; su registro efectivo queda pendiente de confirmación.
Después de registrarlo, iniciar un flujo nuevo: el código obtenido en el flujo
anterior hacia localhost no debe reutilizarse ni enviarse por el chat.

## Pruebas y alcance

Las regresiones verifican redirect Android, prioridad del origin web, propagación
al servicio Google, fallo al abrir OAuth, excepciones, ausencia de navegación
al abrir el navegador, errores del stream, intercambio PKCE mediante el mismo
`getSessionFromUrl` que usa Supabase Flutter, y restauración de sesión persistida.
El servidor de token está simulado, con código/tokens ficticios y validación de
perfil simulada. No certifican una cuenta Google real ni la configuración del
Dashboard. Las dependencias y el almacenamiento de producción no se reemplazan.

## Validación mínima en Samsung S22

Verificación ejecutada:

- `flutter analyze --no-pub`: sin problemas (23,8 s), `android-oauth-analyze.log`.
- `flutter test --no-pub`: `01:08 +702: All tests passed!`, `android-oauth-full-tests.log`.
- Regresiones enfocadas de autenticación: 18 aprobadas, `android-oauth-focused.log`.
- `git diff --check`: código 0, sin errores.
- `flutter build apk --debug --no-pub`: APK generado (27,6 s en la compilación final).
- Instalación con `adb -s R3CT30HX60V install -r`: Success, sin borrar datos.
- Apertura de MainActivity: Status ok, lanzamiento frío.
- Resolución VIEW/BROWSABLE de la URL exacta: `com.example.transporte_inteligente/.MainActivity`.
- Entrega de callback vacío a la app abierta: Status ok, intent recibido por la
  instancia existente. No se abrió Google ni se eligió una cuenta para esta
  comprobación. La entrega Android no certifica la autorización del Dashboard.

Dispositivo: Samsung S22 `R3CT30HX60V`, Android 15/API 35. No se modificaron
opciones de Supabase, la Site URL ni credenciales. Los únicos pasos pendientes
son el registro manual indicado y la prueba de autenticación personal.

1. Registrar la URL exacta anterior y guardar en Supabase.
2. Abrir la aplicación instalada y pulsar **Continuar con Google**.
3. Seleccionar personalmente la cuenta y aceptar los permisos necesarios.
4. Confirmar que el navegador vuelve a la app, se valida el perfil y aparece
   Inicio; no debe terminar en localhost.
5. Cerrar y volver a abrir la app: comprobar que la sesión se conserva.
   Probar también cancelar Google y volver a intentar.

La autenticación real está pendiente de selección/confirmación humana.

Archivos: `lib/config/auth_redirect.dart`, `login_screen.dart`, manifiesto
Android, `auth_redirect_test.dart`, `google_oauth_flow_test.dart`, actualización
de `google_auth_service_test.dart` y este documento. `main.dart` y el servicio
Google no requieren cambios. El diseño y los módulos de movilidad se conservan.

El lockfile ya estaba modificado al comenzar. Se conserva su contenido exacto:
SHA-256 `cf0ea1843a277fb73974690d7759d01fda55f02983292e6562b68b2691a443c3`.
No se aplicó ni eliminó el stash, ni se creó commit, push o PR.

Referencias: [Supabase: enlaces móviles](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter),
[Flutter: manejadores de deep links](https://docs.flutter.dev/ui/navigation/deep-linking).

## Cobertura operativa ampliada (14 de octubre de 2026)

La fase geográfica posterior permite GPS, búsqueda y planificación en
Bucaramanga, Girón y Floridablanca; Piedecuesta está excluida como extremo.
La corrección OAuth anterior, callback y manifiesto se conservan. La evidencia
y pruebas de esa ampliación están en [Cobertura operativa](operational-coverage.md).
En esa fase el S22 no aparece conectado, por lo que el nuevo APK no implica
confirmación de recorridos, publicación real de incidentes ni otra interacción
física. La propuesta académica mantiene sus objetivos originales hasta contar
con aprobación de la tutora; las pruebas de software no son resultados de
movilidad medidos.
