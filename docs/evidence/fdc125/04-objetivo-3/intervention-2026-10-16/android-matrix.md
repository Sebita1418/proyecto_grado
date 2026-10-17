# Matriz Android del corte D

APK 1.0.2+2026101601. Samsung S22 SM-S901U, Android 15/API 35, R3CT30HX60V.
Esta matriz no hereda resultados de los videos de otra versión.

| ID | Comprobación | Estado observado | Evidencia / pendiente humana |
|---|---|---|---|
| AND-01 | Instalar, identificar versión y abrir | PASS instalación, hash y apertura de componente; interfaz NOT TESTED | `install.log`, `installed-version.log`, `installed-apk-hash.log`, `launch.log`. Pantalla bloqueada; esperar desbloqueo |
| AND-02 | Google con selección nueva de cuenta y retorno | NOT TESTED | No se cerró la sesión del usuario ni se eligió cuenta |
| AND-03 | Permiso GPS preciso y ubicación coherente | NOT TESTED | Conceder/confirmar en teléfono, contrastar punto conocido |
| AND-04 | Buscar y confirmar origen/destino | NOT TESTED | Dirección, candidato y coordenada conocida; no suponer placa exacta |
| AND-05 | Ruta y explicación de alternativas | NOT TESTED | Leer «¿Por qué esta ruta?»; debe declarar tráfico no disponible |
| AND-06 | Mismos extremos con vehículo/peatón/bicicleta | NOT TESTED | Comprobar distancias/duraciones consultadas; no ganador automático |
| AND-07 | Reporte próximo y actualización contextual | NOT TESTED | Registrar únicamente incidente auténtico; no crear reportes ficticios en producción |
| AND-08 | Preferencias de modos | NOT TESTED | Cambiar/guardar/recargar, comprobar exclusión y luego restaurar preferencia deseada |
| AND-09 | Salida programada e insuficiencia histórica | NOT TESTED | Debe declarar historial general o error/insuficiencia; sin prometer hora óptima |
| AND-10 | Navegación, movimiento y recentrado | NOT TESTED | Prueba supervisada como pasajero; rumbo, mala señal y arrastre/recentrado |

La instalación técnica es observación directa por ADB, no una validación de
autenticación o conducción. La captura inicial muestra Always On Display y no
demuestra Home. No se atribuye una prueba física funcional aprobada sin observarla
o recibir una confirmación humana específica para esta versión.
