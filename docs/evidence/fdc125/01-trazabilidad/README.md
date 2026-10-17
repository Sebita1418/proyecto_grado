# Trazabilidad A, B y C

| Corte | Fuente de código y pruebas | APK / SHA-256 | Evidencia / validación |
|---|---|---|---|
| A · 14/10 | Working tree sobre 226f1a4; manifiesto de 128 fuentes funcionales; 742 pruebas entonces ejecutadas | 1.0.0 / 20261014 · 040768c25ab2075125957dafe47939f82e57f4299c0a8a78b48b5ef4236fc6c3 | [Informe histórico](../../../android-release-validation.md); instalado/abierto en S22 el 14/10; nuevos flujos no inferidos |
| B · 15/10 | Código posterior con 12 tests de demostración; 754 pruebas aprobadas. [Resumen original](../../objective-3/2026-10-15/run-summary.json). Conserva comprobación de 128 fuentes de aplicación; no hay inventario completo de todos los tests de ese corte | **Sin APK nuevo**. No asignar otro SHA ni decir que 754 pruebas corresponden automáticamente a A | [Auditoría original](../../../objective-3-validation.md); fixtures, no pruebas físicas |
| C · 16/10 | Inventario de 215 fuentes/config/tests; 15e672c04262b4b4d40175334cd784ab9f26ad283166495f90a924c36ec1ac69; ejecución nueva 754 PASS, 0 FAIL, 0 skipped. El test permite ruta de salida para preservar JSON histórico; no cambia producción | 1.0.1 / 20261016 · df46b68345ea3e07fce5eb57a452863fccf33b431e4c76be54361d44727bcd40 | [Build/firma/assets](../07-integridad-y-versiones/README.md); física C no ejecutada |

No se afirma identidad binaria entre A/C ni se atribuye C a videos del 15/10. La funcionalidad fuente puede coincidir con A en el inventario funcional; C cambia versión/build y tiene su propio SHA e inventario probado. El commit base solo no contiene los cambios locales y no basta para reconstrucción.

- [Identidad del corte actual](code-state.json), [hashes de fuente](source-state.sha256).
- [Archivos sin commit antes del build](git-status-before.txt), [estado actual](git-status-current.txt), [diff stat](git-diff-stat.txt), [log Git](git-log.txt), [stash conservado](stash-list.txt), [origin/develop observado](origin-develop.txt).
- [GitHub y privacidad del repo](github-snapshot.json).
- [Publicación preparada, no ejecutada](PUBLICACION.md).

El archivo pubspec.lock conserva su modificación previa y SHA cf0ea1843a277fb73974690d7759d01fda55f02983292e6562b68b2691a443c3. No se aplicó/eliminó stash cc2b34eb080858401908a211262d299111bfd4fe. No reset, clean, restore, commits, push, PR, Release ni cambio de visibilidad.

Durante este cierre solo se cambió el destino configurable de salida del test y .gitignore para versionar logs/excluir binarios y revisión privada; se agregaron documentos, matrices/manifiestos y nueva entrega externa a build. El código funcional local anterior se conserva.
