# AND-01 a AND-10: observación y alcance

Revisión del 16/10/2026. Los clips aportados muestran interacciones reales visibles, pero no versionCode, SHA del APK ni modelo del dispositivo. No se atribuyen a la nueva compilación C. La identidad y fecha de creación de cada grabación requieren confirmación humana; el nombre no las certifica. Se revisaron fotogramas muestreados, no todos los frames ni el audio.

| ID | Objetivo | Estado | Evidencia observada y límite | Enlace |
|---|---|---|---|---|
| AND-01 | Instalación, identidad y apertura | Parcialmente observada | Apertura A observada 14/10 (log/captura previa); versión final C no instalada al no haber dispositivo | [Evidencia](../../../../deliveries/2026-10-14-android-academic/evidence/s22-launch.log) |
| AND-02 | Google OAuth completo | Aprobada | V01 muestra salida de sesión, selector Google y retorno a Home; aprobación limitada al flujo grabado, APK/dispositivo sin identificar | [Evidencia](../06-capturas/V01-t08-google-anonimizada.png) |
| AND-03 | GPS y territorio | Parcialmente observada | V02 mapa/punto y aviso de destino fuera de cobertura (~20 s); no prueba precisión ni todos los límites | [Evidencia](../05-videos-originales/manifest.json) |
| AND-04 | Búsqueda y candidato | Parcialmente observada | V02 búsqueda UIS y destino elegido (~20–30 s); no prueba placa exacta | [Evidencia](../05-videos-originales/manifest.json) |
| AND-05 | Ruta y explicación de alternativa | Parcialmente observada | V02 ruta/nav (~40 s); no se lee un ranking completo y sus motivos | [Evidencia](../05-videos-originales/manifest.json) |
| AND-06 | Mismo OD en caminata/bici | No ejecutada | Tarjetas visibles, sin consulta comparativa acreditada; tests sintéticos separados | [Evidencia](../04-objetivo-3/README.md) |
| AND-07 | Reporte y efecto en recomendación | Parcialmente observada | V02 formulario (~50 s) y analítica 2 registros (~80–85 s); no acredita inserción backend ni cambio de ranking | [Evidencia](../06-capturas/V02-t85-analitica-derivada.png) |
| AND-08 | Preferencias y elegibilidad | No ejecutada | Sin evidencia visual del cambio de preferencias | [Evidencia](../04-objetivo-3/README.md) |
| AND-09 | Programar e historial suficiente/insuficiente | No ejecutada | Analítica de 2 registros no acredita orientación por hora; casos deterministas no sustituyen prueba física | [Evidencia](../06-capturas/V02-t85-analitica-derivada.png) |
| AND-10 | GPS en movimiento, giro, pausa/recentrado | Parcialmente observada | V02 nav/aviso esperando GPS y control volver a seguir (~40–70 s); no acredita movimiento real ni giro por rumbo fiable | [Evidencia](../05-videos-originales/manifest.json) |

**Versión C (1.0.1, 20261016): todas las pruebas físicas No ejecutada.** S22 no conectado en flutter devices el 16/10. Instalar exactamente el APK verificado antes de repetir y completar fecha, persona, dispositivo, versión/hash y observación.

No se declararon fallidas pruebas no ejecutadas. «Aprobada» de AND-02 se limita al flujo visible del video, no a validación física de C ni a auditoría del backend. No se usa analítica de dos reportes como prueba de historial suficiente o reducción de congestión.

Los originales son privados/sensibles y están excluidos de Git. Sus hashes/tamaños están en [manifiesto](../05-videos-originales/manifest.json). Las [capturas derivadas](../06-capturas/manifest.json) no reemplazan a los videos.
