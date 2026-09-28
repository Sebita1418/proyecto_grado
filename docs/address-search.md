# Búsqueda de lugares y direcciones

Photon conserva el autocomplete con debounce de 450 ms y descarte por versión
de consulta. `AddressQuery` expande Cra/Cr, Cl, Av, Diag y Trans únicamente ante
numeración. Conserva la consulta original y separa vía principal, número
secundario y placa: «Cl 69 6-51» representa Calle 69, secundario 6, placa 51.
Reconoce «Calle 45 Carrera 27» y «Calle 45 con Carrera 27» como consultas de
intersección; no construye ni interpola coordenadas para ellas.

Una ciudad explícita tiene prioridad: no se añade Bucaramanga a la consulta.
Sin ciudad, se usa el GPS disponible del panel como bias; si falta, se usa
un centro de demostración metropolitano (7.08, -73.10), **solo para preferencia
de búsqueda**, nunca como resultado. No se añade reverse geocoding ni se deduce
un municipio por cercanía. El panel no dispone del centro del mapa en su
contrato actual. Photon recibe lat/lon; Nominatim recibe un viewbox de ±0,18°,
sin `bounded`, para favorecer resultados cercanos sin excluir otras zonas.
Con ciudad escrita se omiten estos biases. Resultados cuya ciudad informada
contradiga la solicitada se descartan; sin ciudad informada no se certifica
una coincidencia específica con ciudad explícita.

Origen manual y destino usan el mismo servicio. Seleccionar una sugerencia
guarda las coordenadas del proveedor y evita geocodificar nuevamente al
calcular. La etiqueta de Photon incluye número de inmueble cuando está presente.

En consultas de dirección, «Buscar dirección» permite consultar Nominatim si
las sugerencias Photon no sirven. Es una acción explícita, nunca una petición
por tecla. Presenta el resultado para seleccionarlo antes del cálculo. Editar
el campo o desmontar el panel invalida respuestas pendientes y detiene las
variantes siguientes. «Calcular ruta» con dirección sin seleccionar primero
muestra candidatos: el usuario selecciona uno y después calcula. Así, un
resultado de calle no se enruta silenciosamente como si fuera una puerta.
El flujo directo de POI se conserva. Los resultados vacíos no generan rutas.

## Consultas y ranking

Máximo **cuatro solicitudes secuenciales** por resolución explícita de una
dirección completa, con ciudad preservada en cada variante:

1. `Calle 69 # 6-51`.
2. `Calle 69 6-51`; con ciudad explícita se expresa como consulta estructurada
   `street=6-51 Calle 69`, `city=...`, `country=Colombia` (y estado si se escribió).
3. `Calle 69 6 51`.
4. `Calle 69` como último fallback aproximado.

Se detiene cuando existe evidencia específica; un error detiene la secuencia
y conserva candidatos anteriores si existen. Cada consulta de dirección pide
hasta cinco resultados con `addressdetails=1`, ordena y conserva el mejor;
los mejores de las variantes se deduplican y vuelven a ordenar. Photon sigue
haciendo una sola solicitud por consulta con debounce, sin fallback automático
a Nominatim. Las consultas estructuradas nunca combinan `q` con `street/city`.

Ranking lexicográfico determinista, sin pesos: compatibilidad de vía y placa,
ciudad escrita, distancia al bias cuando no hay ciudad explícita, completitud
de campos de dirección y orden del proveedor. Las partes numéricas se comparan
como tokens: `6-51` no equivale a `65-1`. No se modifica la duración OSRM.

## Precisión

«Coincidencia específica» exige vía y numeración compatibles en los campos
devueltos por el proveedor; también ciudad compatible cuando se escribió.
No basta con repetir el texto solicitado en una etiqueta. «Coincidencia
aproximada · numeración exacta no confirmada» identifica calles, intersecciones
no verificadas o datos incompletos/incompatibles. Los POI se identifican como
«Lugar». Se conservan las coordenadas reales y el aviso tras seleccionar.
No hay interpolación de puertas ni editor nuevo de puntos en el mapa.

Nominatim tiene timeout de 8 s, caché de hasta 100 consultas por instancia y
una cola compartida en el proceso con al menos 1 s entre solicitudes. La clave
de caché incluye el bias para no reutilizar otra ubicación por error. Esta
cola **no coordina clientes diferentes**. El servidor público tiene un límite
de 1 solicitud/s para toda la aplicación y prohíbe autocomplete. Una entrega
con tráfico concurrente necesita un proxy con limitación global y caché o una
instancia/proveedor adecuado: https://operations.osmfoundation.org/policies/nominatim/.

La cobertura de OpenStreetMap determina si una puerta o intersección está
indexada. El proveedor puede devolver una calle en vez del inmueble exacto:
la UI muestra la etiqueta recibida, sin inventar numeración ni intersecciones.
Los tests no certifican la existencia actual de una dirección en los datos
públicos; HTTP, GPS y Realtime están controlados en las pruebas.

## Prueba manual de Sebastián

1. Iniciar sesión, habilitar GPS y escribir «Calle 69 # 6-51».
2. Revisar las sugerencias; si no corresponden, pulsar «Buscar dirección».
   Seleccionar el resultado cuya etiqueta corresponda. Si no existe, verificar
   «Calle 69» y registrar la falta de cobertura del inmueble, sin asumir
   que el centro de una calle sea la puerta solicitada.
3. Calcular, comparar alternativas/recomendación, elegir e iniciar ruta.
4. Comprobar vía, icono, distancia y avance de maniobras con GPS real.
5. En otro cliente autenticado publicar un reporte y comprobar que aparece
   durante navegación, tanto en el mapa como en «Reportes de la vía».
6. Arrastrar mapa, volver a seguir ubicación y comprobar continuidad.
7. En un recorrido seguro, registrar tres fixes fuera de ruta (>60 m):
   comprobar «Recalculando ruta…», nueva geometría y maniobras sin reiniciar.
   Repetir sin conexión: la ruta anterior debe conservarse.
8. Llegar (40 m), finalizar y volver a planificación. Probar además
   «Calle 69 # 6-51, Floridablanca», «Carrera 27 # 36-14, Bucaramanga»,
   «Cra 27 36-14, Bucaramanga», «Calle 45 con Carrera 27, Bucaramanga»,
   «UIS» y «Cacique», también en origen manual. Revisar el aviso de precisión
   antes de seleccionar; no asumir que el proveedor tiene todas las placas.

La integración remota se hizo por parches complementarios: panel plegable,
lista de reportes, edición/descarte de borradores, controles y presentación.
Home, estado de navegación y tests V2 locales se conservaron. Los reportes
continúan separados de OSRM: no alteran rutas ni simulan tráfico.
