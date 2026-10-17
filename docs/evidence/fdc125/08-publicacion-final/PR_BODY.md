El flujo Android incorpora el callback Google nativo, cobertura DANE de Bucaramanga/Girón/Floridablanca, búsqueda con selección explícita y seguimiento GPS con política de precisión. Esta revisión reúne los cambios locales conservados y la evidencia académica sanitizada para el F-DC-125.

La validación del objetivo 3 incluye procesamiento por lotes de 39.193 registros oficiales (39.190 válidos, 3 descartados), nueve consultas OSRM con 14 alternativas, reglas explicables y una prueba remota TomTom usando la sesión activa de Flutter. El servidor respondió HTTP 200, 51/51 km/h y confianza 1; cuota 0→1/10 y sin Auth HTTP 401. Los videos privados y fotogramas sin anonimizar no se publican.

## Validación ejecutada en el cierre

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub --machine`: 769 aprobadas, 0 fallidas, 0 omitidas.
- Node: 13 aprobadas, 0 fallidas (unión sin duplicar casos compartidos). Cortes originales: 6 y 11 por separado.
- `git diff --cached --check`: correcto; atributos limitados a evidencia preservan sus bytes/espacios originales.

## Artefacto y límites

APK conservado: 1.0.2/2026101601, 60.331.195 bytes, SHA-256 `435913b6c1eb08ace49d80005f7b20d4561a1428fa9d254ba45a769384d9eb40`, firma Android Debug. No se recompiló para el cierre. El APK no habilita TomTom: la consulta fue un diagnóstico temporal con otro hash y después se restauró el académico. TomTom no cambia ranking o duración OSRM. No se afirman Big Data completo, ahorro real de tiempo, horario óptimo ni cobertura general.

Entrada principal: `docs/evidence/fdc125/README.md`; matriz, texto para F-DC-125, inventario y controles de privacidad en `08-publicacion-final/`. El literal aprobado de F-DC-124 sigue pendiente de cotejo. El lock previo se incluye sin modificar bytes ni aplicar stash para conservar trazabilidad de dependencias.

Base: develop. No fusionar sin revisión y aprobación. Repositorio y Release permanecen privados; la evaluadora requiere acceso autorizado.