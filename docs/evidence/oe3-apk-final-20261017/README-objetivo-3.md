# Objetivo específico 3 — versión Android

## APK archivada

- **Versión:** 1.0.3+2026101701
- **Archivo:** `transporte-inteligente-oe3-1.0.3-2026101701.apk`
- **SHA-256:** `E30200370D01AFDBC43BDCFDEAC0CAD06490303CD80FB54B94D03CEC5A4F1867`
- **Origen:** copia del APK verificado en `deliveries/objective-3-verification-20261017/`.

## Funcionalidad del objetivo 3

La aplicación consulta agregados históricos de movilidad almacenados en Supabase y muestra su periodo y procedencia. Compara alternativas de automóvil, bicicleta y caminata mediante rutas OSRM, y calcula una recomendación entre las alternativas disponibles según las preferencias seleccionadas y sus distancias y duraciones calculadas.

## Alcance comprobado y límites

La lectura autenticada de los 196 agregados y el flujo de comparación y recomendación quedaron verificados en la versión 1.0.3. La integración probada de rutas usa OSRM. No se verificó que TomTom Routing esté habilitado para la cuenta ni que el tráfico modifique el ranking; una lectura anterior de TomTom Traffic Flow correspondió a un segmento y no se extrapola al trayecto completo. No se presentan horarios óptimos, tiempos de transporte público ni capacidades Big Data como funcionalidades demostradas.

Esta es la última APK generada y verificada disponible en el proyecto para el objetivo 3
