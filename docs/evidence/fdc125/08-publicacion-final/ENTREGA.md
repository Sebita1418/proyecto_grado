# Publicación académica y acceso

Repositorio privado: https://github.com/Sebita1418/proyecto_grado. Publicación autorizada por el usuario el 16/10/2026 desde `feature/android-end-to-end-validation` hacia `develop`. No se autoriza ni realiza merge, push directo a main/develop, cambio de visibilidad o divulgación de videos privados. Los documentos anteriores que decían «no ejecutado» son registros de cortes previos; el resultado vigente se acredita con `PUBLICACION.json` y las URLs reales.

## APK a distribuir

Archivo: `transporte-inteligente-1.0.2-2026101601-release-debug-signed.apk`. Tamaño: 60.331.195 bytes. SHA-256: `435913b6c1eb08ace49d80005f7b20d4561a1428fa9d254ba45a769384d9eb40`. No se compiló de nuevo. Se adjuntan hash, instrucciones originales, ficha de versión y manifiesto de fuentes.

Release académica privada, no producción: firma Android Debug, minSdk24/targetSdk36, sin TomTom habilitado. El commit de publicación incorpora evidencias y código posterior de servidor/diagnóstico; la identidad binaria y las fuentes del APK son las del manifiesto original. No se atribuye al binario una funcionalidad por el mero hecho de existir en el commit posterior.

Instalación: verificar SHA-256; transferir APK al Android y autorizar la instalación desde la aplicación que lo abre; o usar `adb install -r <APK>`. Conservar datos/sesión; no desinstalar para actualizar. Activar GPS preciso y red para funciones online. No manipular el teléfono al conducir. Los flujos no observados conservan NOT TESTED.

## Acceso para la evaluadora

Los enlaces del PR, evidencias y Release requieren una cuenta GitHub con acceso a este repositorio privado. No basta conocer la URL. El propietario debe solicitar el usuario GitHub exacto de la evaluadora y, con autorización, conceder solo lectura desde Settings → Collaborators/Access; comprobar la apertura con ella. No se envían invitaciones por nombres supuestos ni se cambia el repositorio a público.

Videos originales: permanecen locales y excluidos de Git/Release. Para acceso restringido, revisar cada clip y audio, obtener autorización específica, acordar destinataria y alojar una copia revisada en Drive/OneDrive con acceso «personas específicas», lectura y sin enlace público; verificar con la evaluadora. No se subieron ni se crearon enlaces ficticios. Si la revisión no está lista, compartir solo las capturas anonimizadas y los manifiestos de integridad.

## Dependencias y trabajo previo

Se preservan los bytes del lock de trabajo previo (SHA `cf0ea1843a277fb73974690d7759d01fda55f02983292e6562b68b2691a443c3`) y el stash. Se incluye ese lock existente en el commit autorizado para documentar dependencias; no se regeneró ni se aplicó/borró el stash. Los cambios funcionales locales de fases anteriores se publican como parte de la revisión y no se atribuyen únicamente al cierre documental.

## Privacidad

El control revisó candidatos de publicación y capturas: sin secretos de servidor, JWT, contraseñas ni videos privados. Los correos detectados pertenecen a fixtures de pruebas, no a cuentas observadas. La configuración Supabase usa la clave publicable del cliente prevista para distribución, que no sustituye autenticación ni concede privilegios de servicio; ningún TOMTOM_API_KEY o service_role se publica. Estado local de CLI, `.env`, almacenes de firma, artefactos y directorios de revisión permanecen excluidos.

No se promete anonimato o acceso anónimo a un repositorio privado. `PUBLICACION.json` registra exclusivamente URLs devueltas/verificadas después de publicar.

## Enlaces publicados y verificados

- [PR #58 hacia develop](https://github.com/Sebita1418/proyecto_grado/pull/58).
- [Índice maestro remoto](https://github.com/Sebita1418/proyecto_grado/blob/feature/android-end-to-end-validation/docs/evidence/fdc125/README.md).
- [Release académica privada](https://github.com/Sebita1418/proyecto_grado/releases/tag/academic-20261016-v1.0.2).
- [Descarga APK 1.0.2](https://github.com/Sebita1418/proyecto_grado/releases/download/academic-20261016-v1.0.2/transporte-inteligente-1.0.2-2026101601-release-debug-signed.apk).

La descarga autenticada se verificó por tamaño y SHA-256; GitHub también informa el digest idéntico. No se probó acceso desde una cuenta de evaluadora aún no identificada/autorizada. No hay comprobaciones CI configuradas/reportadas para el PR al momento de consulta; la validación local está en FINAL-QA.json.
