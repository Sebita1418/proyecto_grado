# Navigation Mode V2

OSRM solicita `steps=true`, `overview=full` y `geometries=geojson`, conservando
las alternativas. Cada step aporta maniobra, dirección, vía, posición, distancia
y duración. Si faltan steps o son defectuosos se conserva la ruta sin inventar
guía; los tipos desconocidos tienen una indicación neutral.

La distancia a maniobra usa la proyección GPS y la posición de la maniobra sobre
la geometría. La distancia acumulada de los steps ayuda a resolver coordenadas
repetidas. Tras superar una maniobra por 12 m se avanza y no se retrocede por
jitter. Es una aproximación local, no map matching de carriles.

Tres posiciones consecutivas a más de 60 m confirman desvío. Se pide la ruta
primaria OSRM desde el GPS al destino original, con una petición activa y
cooldown de 30 s entre intentos. Un error mantiene la ruta anterior; una nueva
lectura tras el cooldown permite reintentar. No hay polling ni timer de reroute.
Las respuestas tras finalizar/dispose, volver a la ruta o llegar se ignoran.
Si el GPS avanzó más de 100 m y quedó fuera de la nueva geometría, se descarta
la respuesta. Los fixes con timestamp no creciente también se ignoran.

Al recalcular se reproyecta el último GPS sobre la nueva geometría y se cambian
steps y métricas, sin reabrir alternativas. Al finalizar se vuelve al resultado
de planificación previamente seleccionado. Los reportes no afectan OSRM.

Panel superior de maniobra, resumen inferior y cámara norte-arriba con encuadre
desplazado; arrastrar pausa el seguimiento. No se inventa heading. Llegada a
40 m del destino; duración restante proporcional, sin tráfico dinámico.
Solo foreground: sin voz ni servicios en segundo plano.

Validación manual: elegir alternativa, iniciar, avanzar y observar distancia y
cambio de maniobra; desviarse, comprobar recálculo y continuidad; repetir sin
red, recentrar tras arrastrar, publicar/recibir reportes y finalizar al llegar.
Los tests usan HTTP y GPS controlados; la precisión GPS real debe probarse en
dispositivo. Referencia: [OSRM RouteStep](https://project-osrm.org/docs/v5.24.0/api/#routestep-object).
