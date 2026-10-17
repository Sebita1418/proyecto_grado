# Integridad y nueva versión final académica

**C: 1.0.1 / 20261016**, release firmado con Android Debug (APK v2, no producción). Application ID com.example.transporte_inteligente; minSdk 24, target/compile 36. Tamaño **60.331.195 bytes**.

SHA-256:

    df46b68345ea3e07fce5eb57a452863fccf33b431e4c76be54361d44727bcd40

- [Metadata final](version-final.json), [checksum](APK-SHA256SUMS.txt) y [comando/tiempos de build](build-command.json).
- [Build original](build-final-original.log), [firma](signature-original.log), [identidad/SDK/permisos](badging-original.log), [manifest empaquetado](manifest-original.log), [assets verificados](assets-original.log).
- [Código probado](../01-trazabilidad/source-state.sha256): huella 15e672c04262b4b4d40175334cd784ab9f26ad283166495f90a924c36ec1ac69.
- [Inventario original previo](originals-baseline.json) y [privacidad](privacy-review.json).

APK local (excluido de Git): deliveries/version-final-academica/transporte-inteligente-1.0.1-20261016-release-debug-signed.apk. Se entrega con version.json, SHA256SUMS.txt, source-state.sha256, verify-apk.ps1 e instrucciones. No se sobrescribió el APK A.

Compilación:

    flutter build apk --release --no-pub --build-name=1.0.1 --build-number=20261016

La compilación comenzó después de QA aprobada del mismo inventario de 215 archivos, incluyendo tests y lock. Gradle informó 290,2 s, exitCode=0; avisos XML del SDK no invalidaron la compilación. El certificado coincide con la clave debug existente, no se modificó firma ni credenciales. El número se pasó como argumento; pubspec.yaml no se reescribió.

Verificación local:

    Get-FileHash -Algorithm SHA256 -LiteralPath "deliveries/version-final-academica/transporte-inteligente-1.0.1-20261016-release-debug-signed.apk"
    & ".\deliveries\version-final-academica\verify-apk.ps1"

apksigner verify confirmó firma v2. Se leyeron del ZIP los tres GeoJSON en assets/flutter_assets/assets/geo/; longitudes y hashes coinciden con archivos fuente. El callback transporteinteligente://login-callback/ y MAIN/LAUNCHER se conservaron en el manifest empaquetado. Permisos Internet y ubicación precisa presentes.

No se suministraron nuevas claves/variables ni dependencias. GOOGLE_ROUTES_API_KEY pertenece al módulo heredado; el flujo principal conserva OSRM. Configuración de Dashboard Supabase y servicios remotos no certificada por compilar.

S22 no conectado en [inventario real](../03-pruebas-android/devices-original.log): instalación/apertura y flujos físicos C **No ejecutada**. Para validar, conectar el teléfono, instalar exactamente este APK y registrar su hash/versionCode antes de completar AND-01..10. No desinstalar una versión previa por conflicto de firma sin revisar datos.

Los logs y manifiestos originales se conservan. La lista SHA256SUMS.json de esta sección registra hashes por archivo del conjunto institucional (sin autorreferencia ni duplicar videos). Integridad no acredita cumplimiento académico, exactitud del proveedor ni anonimización total de originales.
