# Publicación preparada — NO EJECUTADA

Repositorio existente: https://github.com/Sebita1418/proyecto_grado. Es privado; GH CLI 2.101.0 autenticado, sin registrar valores de tokens. `origin/develop` local y remoto observados en `226f1a4fb04fcc8b5bc8a2aed4e7e4a550b71fa4`. Rama de trabajo: `feature/android-end-to-end-validation`. Base PR: `develop`, no `main`.

**Estos comandos no son una autorización.** No se hizo commit, push, PR, tag, Release ni cambio de visibilidad. Revisar diff, privacidad y artefactos antes de ejecutarlos tras aprobación posterior.

## 1. Revisión previa

```powershell
git branch --show-current
git status --short
git diff --check
git diff --stat
git diff -- pubspec.lock
gh auth status
```

`pubspec.lock` ya estaba modificado antes de esta fase, se conservó y forma parte del hash del código probado. **Resolver expresamente si se autoriza incorporar ese estado previo al commit**: omitirlo sin más deja una brecha de reproducción de dependencias. No aplicar el stash ni regenerar el lock para resolverlo. La ejecución `--no-pub` usa paquetes ya disponibles; no promete reconstrucción desde el commit base solo.

Revisar [riesgos de privacidad](../07-integridad-y-versiones/privacy-review.json). Los dos videos originales y hojas de revisión contienen información privada y están excluidos. No usar `git add -f` ni añadir `deliveries/`. Los logs originales sí quedan versionables por excepción limitada en `.gitignore`.

## 2. Commit y PR, solo con autorización

Después de revisar los cambios funcionales locales anteriores y resolver el lock:

```powershell
git add -- .gitignore android/app/src/main/AndroidManifest.xml assets docs lib test pubspec.yaml
# Solo si se autoriza incorporar el lock previo, sin modificar su contenido:
# git add -- pubspec.lock
git diff --cached --check
git diff --cached --stat
git diff --cached --name-only
# Revisar que no haya APK/ZIP/video, cuentas, conversaciones ni claves.
git commit -m "feat: finalize academic Android validation and FDC125 evidence"
git push -u origin feature/android-end-to-end-validation
gh pr create --base develop --head feature/android-end-to-end-validation --title "Academic Android delivery and FDC125 validation evidence" --body-file docs/evidence/fdc125/01-trazabilidad/PR_BODY.md
```

No se prepara un commit limitado a documentos fingiendo que el APK proviene del commit base: las funciones locales sin commit también deben revisarse. Si durante revisión cambia código, ejecutar otra vez QA y comparar inventarios; no atribuir esos cambios a C sin nueva compilación/identificador. No fusionar automáticamente.

## 3. Release académica, tras aprobar y fijar commit

Elegir el SHA definitivo revisado y probado; no etiquetar un commit que no contiene el estado probado como si lo contuviera. Revalidar hash del APK y relación con ese commit. Si merge/revisión cambian fuentes, reconstruir y documentar antes de publicar.

```powershell
# Sustituir SHA_APROBADO_PROBADO por el commit real; no ejecutar el placeholder.
gh release create academic-20261016 --target SHA_APROBADO_PROBADO --title "Transporte Inteligente — entrega académica 16/10/2026" --notes-file docs/evidence/fdc125/01-trazabilidad/RELEASE_NOTES.md --draft
gh release upload academic-20261016 "deliveries/version-final-academica/transporte-inteligente-1.0.1-20261016-release-debug-signed.apk" "deliveries/version-final-academica/SHA256SUMS.txt" "deliveries/version-final-academica/version.json"
# Revisar la Release borrador y publicar solo con autorización explícita posterior.
```

Los originales de video no se incluyen en estos comandos: primero revisar datos personales y audio y acordar destinatarios/acceso. Si se autorizan expresamente, añadirlos como assets conservando nombres y SHA; no sustituirlos por capturas. La firma es Android Debug para demostración, no distribución de producción.

## 4. Enlaces futuros y acceso de directora

Son destinos **previstos**, todavía no publicados ni definitivos:

- Evidencias de rama después del push: `https://github.com/Sebita1418/proyecto_grado/tree/feature/android-end-to-end-validation/docs/evidence/fdc125`.
- Evidencia estable tras merge: `https://github.com/Sebita1418/proyecto_grado/tree/develop/docs/evidence/fdc125`.
- Release propuesta: `https://github.com/Sebita1418/proyecto_grado/releases/tag/academic-20261016`.
- APK futuro: `https://github.com/Sebita1418/proyecto_grado/releases/download/academic-20261016/transporte-inteligente-1.0.1-20261016-release-debug-signed.apk`.
- PR: URL que devuelva `gh pr create`, sin inventar número.

Para repositorio privado, solicitar a la directora su usuario GitHub y autorizar invitación de lectura desde `https://github.com/Sebita1418/proyecto_grado/settings/access`. No cambiar a público ni invitar por nombre supuesto. Sin acceso autenticado aprobado, los enlaces privados no serán visibles para ella.
