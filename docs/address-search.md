# Búsqueda de lugares y direcciones

Photon conserva el autocomplete con debounce de 450 ms y descarte por versión
de consulta. `AddressQuery` expande Cra/Cr, Cl, Av, Diag y Trans únicamente ante
numeración. No modifica el texto escrito en los campos. Las direcciones que
solo contienen numeración usan el contexto de proyecto Bucaramanga, Colombia;
las ciudades o barrios escritos se conservan, sin límites espaciales nuevos.

Origen manual y destino usan el mismo servicio. Seleccionar una sugerencia
guarda las coordenadas del proveedor y evita geocodificar nuevamente al
calcular. La etiqueta de Photon incluye número de inmueble cuando está presente.

En consultas de dirección, «Buscar dirección» permite consultar Nominatim si
las sugerencias Photon no sirven. Es una acción explícita, nunca una petición
por tecla. Presenta el resultado para seleccionarlo antes del cálculo. Editar
el campo o desmontar el panel invalida respuestas pendientes. «Calcular ruta»
con texto sin seleccionar conserva la geocodificación explícita existente.
Los resultados vacíos no generan coordenadas ni rutas.

Nominatim tiene timeout de 8 s, caché de hasta 100 consultas por instancia y
una cola compartida en el proceso con al menos 1 s entre solicitudes. Esta
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

1. Iniciar sesión, habilitar GPS y escribir «Carrera 27 # 10-15, Bucaramanga».
2. Revisar las sugerencias; si no corresponden, pulsar «Buscar dirección».
   Seleccionar el resultado cuya etiqueta corresponda. Si no existe, verificar
   «Carrera 27» y registrar la falta de cobertura del inmueble, sin asumir
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
   «Cra 33 # 48-21», «Calle 5, Floridablanca», una dirección en otra ciudad,
   «Carrera 33 con Calle 52», «UIS» y «Cacique», también en origen manual.

La integración remota se hizo por parches complementarios: panel plegable,
lista de reportes, edición/descarte de borradores, controles y presentación.
Home, estado de navegación y tests V2 locales se conservaron. Los reportes
continúan separados de OSRM: no alteran rutas ni simulan tráfico.
