# Capturas derivadas y privacidad

Estas imágenes se extrajeron de los videos originales y se identifican en [manifest.json](manifest.json) con timestamp solicitado, transformaciones y hashes. Se aplicaron máscaras negras explícitas para ocultar datos; las métricas no fueron reescritas. Los originales permanecen íntegros.

- [Selector Google anonimizado, V01 t=8 s](V01-t08-google-anonimizada.png).
- [Retorno Home con mapa ocultado, V01 t=17 s](V01-t17-home-anonimizada.png).
- [Analítica observada, V02 t=85 s](V02-t85-analitica-derivada.png).

La carpeta revision-local está excluida de Git: contiene hojas de revisión no anonimizadas. No publicarla. No hay nueva captura del S22 final C porque no estaba conectado. Referencia anterior de apertura A: [informe original](../../../android-release-validation.md).

Procedimiento: ffprobe obtiene duración/resolución; ffmpeg extrae un fotograma en el segundo indicado y drawbox aplica máscaras. Un fotograma no acredita continuidad temporal ni integridad de un flujo completo; revisar el original y documentar versión antes de ampliar conclusiones.
