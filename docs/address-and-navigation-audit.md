# Auditoría de direcciones y navegación GPS

Fecha: 14 de octubre de 2026. Rama: feature/android-end-to-end-validation.

## Problemas reproducidos y causas

1. **Placa incompleta tratada como establecimiento.** Calle 52 # 3, Floridablanca no coincidía con el patrón de placa completa: perdía contexto municipal y podía pasar a resolución automática de un solo punto. Ahora se conserva vía, número incompleto y ciudad, con búsqueda explícita y selección. No se completa la placa.
2. **Abreviaturas sin espacio.** Cra4 y Cra.4 no se expandían. Se normalizan a Carrera 4. Giron sin tilde se reconoce como localidad. Un error como Carera se conserva para tolerancia del proveedor; no se corrige la numeración a ciegas.
3. **Ambigüedad de establecimientos.** Nominatim pedía un solo candidato para nombres; el teclado iniciaba cálculo directamente. Ahora la confirmación del teclado y el botón de búsqueda muestran hasta cinco candidatos, también para nombres. El usuario elige el punto y solo después analiza la ruta. La API search conserva su primer resultado por compatibilidad con otros módulos y el botón Analizar rutas mantiene el flujo existente para nombres sin selección; para comprobar ambigüedad se debe usar Buscar dirección o la tecla Buscar.
4. **Errores ocultos.** La pantalla sustituía fallos concretos de Photon por un mensaje genérico. Ahora muestra el estado disponible. Si la resolución explícita Nominatim termina sin candidatos, se permite una consulta Photon; HTTP 429 u otro fallo no activa una cascada de proveedores.
5. **Candidatos de otra vía.** Photon respondió Carrera 48 a una consulta Carrera 4. Ahora se reconoce el nombre de entidades highway como vía y se advierte cuando la vía devuelta no coincide. Permanece seleccionable con precisión aproximada: no se presenta como placa ni como proximidad demostrada.
6. **Cámara sin rumbo ni precisión.** La navegación anterior descartaba velocidad, heading y exactitud de Geolocator y movía el mapa norte-arriba de inmediato. Se transportan metadatos del stream a una política de cámara; se anima el encuadre y se rechazan fixes muy imprecisos antes de actualizar progreso, llegada o recálculo.

## Consultas reales y calidad

Se hicieron 18 solicitudes diagnósticas puntuales, secuenciales, con pausa de 1,1 s y User-Agent propio. No forman parte del funcionamiento ni de las pruebas automáticas. Respuestas, URL exacta, hora UTC, identificadores OSM y licencias se conservan en [fixture de auditoría](../test/fixtures/address-provider-audit.json). Las primeras 14 consultas comparan texto literal; las cuatro finales contrastan una consulta estructurada, contexto normalizado y una errata. No todas las consultas literales son las que envía hoy la app. La query estructurada usa street=48-25 Carrera 4, city=Floridablanca y country=Colombia; revisar URL del fixture.

| Texto enviado | Proveedor | Coordenadas devueltas (latitud, longitud) | Evidencia / resultado |
|---|---|---|---|
| Carrera 4 # 48-25, Floridablanca | Photon | Ninguna | Sin resultados |
| Carrera 4 # 48-25, Floridablanca | Nominatim | 7.0631718, -73.0897536<br>7.0693023, -73.0944817<br>7.0791617, -73.0978139<br>7.0613168, -73.0890310<br>7.0705799, -73.0823657 | Vías o nombres; placa no confirmada |
| Cra 4 # 48-25 | Photon | 4.3448272, -74.3659347<br>47.1435318, 29.3114116<br>44.3278645, 23.811192<br>35.3411432, 25.1341502<br>35.3411979, 25.1341596 | Coincidencias ajenas; placa solicitada no confirmada |
| Cra 4 # 48-25 | Nominatim | Ninguna | Sin resultados |
| Calle 52 # 3, Floridablanca | Photon | Ninguna | Sin resultados |
| Calle 52 # 3, Floridablanca | Nominatim | 7.0881285, -73.0927081 | Vías o nombres; placa no confirmada |
| Calle 45 con Carrera 27, Bucaramanga | Photon | 7.1169017, -73.1150764<br>7.1175726, -73.1151382<br>7.1173504, -73.1146152<br>7.1175275, -73.1146555<br>7.1390943, -73.1202474 | Establecimientos/vías; intersección no confirmada |
| Calle 45 con Carrera 27, Bucaramanga | Nominatim | Ninguna | Sin resultados |
| PC System | Photon | 40.4817499, 18.0509569<br>51.7516673, 18.0707758<br>45.3573074, 9.2235144<br>45.883438, 12.714685<br>43.701481, 10.6204127 | Homónimos; ubicación local no confirmada |
| PC System | Nominatim | 4.5590050, -74.1209106 | Homónimos; ubicación local no confirmada |
| Cra 4 | Photon | 5.9571581, -72.946311<br>5.9572811, -72.946305<br>8.3536438, -72.4136373<br>6.0126047, -73.6734035<br>45.278481, -75.7641772 | Coincidencias ajenas; placa solicitada no confirmada |
| Cra 4 | Nominatim | 4.8127879, -74.0272739<br>4.6433929, -74.0595945<br>4.6935817, -74.1729530<br>4.5824472, -74.0813983<br>4.6593624, -74.0496744 | Vías o nombres; placa no confirmada |
| Carrera 4 # 48-25, Giron | Photon | Ninguna | Sin resultados |
| Carrera 4 # 48-25, Giron | Nominatim | Ninguna | Sin resultados |
| Carrera 4 48-25, Floridablanca | Nominatim | 7.0631718, -73.0897536<br>7.0693023, -73.0944817<br>7.0791617, -73.0978139<br>7.0613168, -73.0890310<br>7.0705799, -73.0823657 | Vías o nombres; placa no confirmada |
| Carrera 4 # 48-25, Bucaramanga, Santander, Colombia | Photon | 7.1296746, -73.1069812<br>7.1090297, -73.104827<br>7.1064122, -73.1050748<br>7.0895715, -73.144943<br>7.1121737, -73.10341 | Vías o nombres; placa no confirmada |
| PC System, Floridablanca | Nominatim | Ninguna | Sin resultados |
| Carera 4 # 48-25, Floridablanca | Photon | Ninguna | Sin resultados |

Nominatim devolvió cinco segmentos distintos de Carrera 4 en Floridablanca sin house_number, incluso en búsqueda estructurada: no hay evidencia de placa 48-25 en esta muestra. Calle 52 devolvió un tramo, sin placa 3. La intersección pedida no fue resuelta por Nominatim y Photon propuso establecimientos cercanos en texto, sin certificar el cruce. PC System produjo homónimos de otros países en Photon y uno en Bogotá en Nominatim; con Floridablanca explícita Nominatim devolvió vacío. Esto demuestra límites de las respuestas observadas, **no la inexistencia del establecimiento o de las direcciones en el mundo real**. No se consultó Google Maps como API ni se obtuvieron puntos de referencia del teléfono para medir error en metros.

## Consulta, clasificación y territorio

Se mantiene el contexto municipal derivado del GPS validado por polígonos de Bucaramanga, Girón o Floridablanca. La ciudad escrita tiene prioridad. Sin GPS municipal identificado se conserva el contexto de Bucaramanga existente: añadir la ciudad evita esa ambigüedad. El filtro textual de ciudad se mantiene; no se usa como autorización territorial. Nominatim no usa bounded=1; el viewbox existente es un sesgo, no una geocerca. Photon lat/lon también es sesgo y se retira al incluir ciudad. No se añade un radio restrictivo ni se amplía la geocerca para aceptar resultados.

La precisión específica requiere coincidencia de vía, placa completa y ciudad; vías, cruces y placas incompletas siguen aproximados. No se interpolan números. La selección conserva exactamente las coordenadas del candidato y notifica al mapa; editar texto invalida marcador y ruta previa. Los contadores de petición protegen debounce, resolución explícita y fallback frente a respuestas obsoletas. Se captura el sesgo GPS antes de esperar operaciones asíncronas. El debounce Photon sigue en 450 ms; Nominatim solo se usa por acción explícita y limita variantes a cuatro, con caché de hasta 100 consultas y cola de una solicitud por segundo en el proceso.

Los polígonos DANE y Piedecuesta excluida se conservan. Se valida el origen/destino antes de OSRM y al iniciar navegación. Un recorrido puede atravesar otros municipios. OSRM conserva geometría, distancia e instrucciones del proveedor; no recibe coordenadas calculadas por el normalizador. La selección manual permanece disponible y declara que no confirma una dirección postal.

## Seguimiento GPS implementado

La cámara sigue al iniciar navegación. NavigationCamera guarda punto fiable, rotación 2D y zoom configurable mediante HomeScreen.navigationZoom (16 por defecto, encuadre limitado a 14–18). Rumbo GNSS: speed >= 2 m/s, accuracy <= 25 m y headingAccuracy <= 25 grados, valores finitos y rumbo entre 0 y 360. El rumbo no equivale al compás del dispositivo ni al rumbo de un segmento de ruta; no se integra compás y no se suplanta heading ausente con la geometría OSRM.

La transición de posición, zoom y ángulo tarda 650 ms con easeInOut y el camino angular más corto al cruzar norte. Se parte del punto de anclaje actual para evitar sumar bruscamente el desplazamiento de pantalla. El vehículo queda abajo del centro en pantallas altas; se conserva el ajuste superior en pantallas de menos de 600 px para proteger los paneles existentes. En pantalla ancha también se reserva espacio al panel lateral. No hay inclinación ni perspectiva 3D.

Accuracy > 50 m, negativa o no finita conserva la última posición, evita falsa llegada/desvío y muestra GPS impreciso; el siguiente fix válido recupera seguimiento sin reiniciar la ruta. A velocidad < 1 m/s se mantiene el rumbo y se ignora jitter de cámara dentro de la exactitud reportada (umbral 5–25 m). El marcador de sesión sigue el último fix aceptado: no se ocultan grandes movimientos. Fixes antiguos con timestamp se descartan. Los primeros fixes de locate y gateways que solo aportan coordenadas carecen de metadatos: pueden actualizar posición, pero no autorizan rotación. Los errores de permiso o pérdida del stream conservan la conducta existente de finalizar y reintentar.

Arrastrar el mapa pausa seguimiento y animación. Recentrar vuelve al último punto fiable. La ruta anterior permanece ante fallos de recálculo. Estos umbrales son una política conservadora verificable en software, pendiente de ajustar con recorridos reales seguros.

## Estilo y comparación con Google Maps

Se conservan tiles raster OSM Carto, tema, paneles y controles Figma. La ruta activa aumenta de 5 a 7 px y su borde blanco de 2 a 3 px durante navegación para mejorar contraste; GPS, origen, destino e incidentes mantienen sus símbolos. Instrucciones y botón de recentrado existentes se conservan. No se cambió proveedor ni se agregaron dependencias.

| Función | Estado de esta app / comparación verificable |
|---|---|
| Placas locales | La muestra OSM no acredita las placas citadas; el usuario informó diferencia con Google Maps, sin coordenadas comparables verificadas |
| Selección ambigua | Lista de candidatos y elección explícita por teclado/botón de búsqueda |
| Rutas | OSRM, sin tráfico en vivo ni promesa de equivalencia con rutas Google |
| Cámara | Seguimiento y rotación 2D suavizados, rumbo GNSS condicionado por calidad |
| 3D, voz, tráfico | No se incorporan ni se atribuyen capacidades no comprobadas |
| Precisión real | Pendiente medir contra ubicaciones verificadas, nunca contra datos inventados |

## Límites y alternativas que requieren aprobación

**Nominatim público**: la [política oficial](https://operations.osmfoundation.org/policies/nominatim/) exige como máximo 1 solicitud/s sumando usuarios, atribución y caché; prohíbe autocomplete. La cola local existente no controla tráfico agregado de varios teléfonos y el endpoint permanece fijo. Antes de despliegue multiusuario hace falta resolver proveedor configurable y límite agregado, mediante infraestructura autorizada o un servicio adecuado. No se declara que la cola por proceso satisface ese límite global. Photon permite typeahead pero su [servicio público](https://photon.komoot.io/) puede limitar uso y no ofrece disponibilidad garantizada. Ambos parten de OSM: cambiar entre ellos no agrega placas ausentes.

| Servicio evaluado | Cobertura y precisión | Costos/límites publicados consultados | Integración/licencia y decisión |
|---|---|---|---|
| TomTom | Su [matriz Search](https://docs.tomtom.com/search-api/documentation/product-information/market-coverage) incluye Colombia a nivel de dirección puntual, interpolación, calle y ciudad; no certifica estas placas y la matriz indica edición 2022 | [Tarifas](https://docs.tomtom.com/pricing): Geocoding 20.000 solicitudes mensuales gratuitas; excedentes dependen de producto/contrato y deben cotizarse | API HTTP con key; distinguir punto de dirección e interpolación, verificar condiciones de almacenamiento y mapas de terceros antes de prueba autorizada |
| Geoapify | [Geocoding global](https://apidocs.geoapify.com/docs/geocoding/); no se ha medido cobertura de placas locales, parte de datos abiertos | [Planes](https://www.geoapify.com/pricing/): 3.000 créditos/día, hasta 5 solicitudes/s; plan API10 USD59/mes; geocoding simple consume un crédito | REST con key, fácil adapter; atribución Geoapify y fuentes. No asumir que resuelve datos faltantes de OSM |
| Google Geocoding | No se probó API ni cobertura de estos casos; el comportamiento del producto Maps informado por el usuario no verifica resultados de la API | [Tarifas](https://developers.google.com/maps/billing-and-pricing/pricing): 10.000 eventos gratuitos/mes; primer tramo pagado USD5/1.000 para Geocoding | Billing/key; [políticas](https://developers.google.com/maps/documentation/geocoding/policies) restringen almacenamiento y requieren Google Map si se muestran resultados en mapa. No es un fallback directo para el mapa OSM actual |

Para tiles, [MapTiler](https://www.maptiler.com/cloud/pricing/) publica plan Free con 100.000 peticiones/mes, 5.000 sesiones/mes y estilos personalizables; tiles XYZ raster permiten conservar flutter_map, requieren key y atribución visible MapTiler/fuentes según [condiciones](https://www.maptiler.com/terms/cloud/). El plan Free se orienta a pruebas/uso personal o no comercial; Flex publica USD30/mes, 500.000 peticiones/mes y USD0,15/1.000 peticiones adicionales. Revalidar tarifa y tipo de tile antes de contratar; no se configura. [Geoapify Maps](https://www.geoapify.com/pricing-details/) también ofrece estilos raster y cuenta 0,25 créditos por tile: mejorar fondo no mejora el geocodificador. El cambio comercial requiere aprobación. OSM público es best-effort y su [política de tiles](https://operations.osmfoundation.org/policies/tiles/) exige identificación, atribución visible, caché y ausencia de descargas masivas/offline; no se verificó una caché persistente Android en este trabajo.

Antes de contratar, evaluar con un conjunto de direcciones confirmadas por el usuario y medir distancia, placa coincidente, tasa de vacío, licencia para combinar con el mapa, límite agregado y costo esperado. Ninguna key, contratación ni migración realizada.

## Pruebas y estado Git

Validación: flutter analyze --no-pub sin incidencias (4,1 s); flutter test --no-pub: 742 pruebas aprobadas (1 min 24 s); git diff --check: código 0. Evidencia en address-navigation-verified-analyze.log y address-navigation-verified-tests.log. Pruebas nuevas reproducen respuestas reales almacenadas, abreviaturas, placa incompleta, error tipográfico, confirmación de teclado, candidatos ambiguos, selección exacta, vacío, fallo, fallback y descarte obsoleto. Política GPS cubre rumbo, paso por norte, detenido, precisión, recuperación, pausa/recentrado y evita recálculo por fix impreciso. Integración Home verifica fotogramas de rotación y anclaje en cinco tamaños, mantiene pruebas de incidentes, instrucciones y recálculo. La suite existente cubre origen/destino de distintos municipios, límites, OAuth Android y módulos de movilidad.

APK debug compilado con flutter build apk --debug --no-pub (139,7 s), en build/app/outputs/flutter-apk/app-debug.apk. Gradle terminó con código 0 y Flutter confirmó Built; el shell PowerShell marcó stderr por una advertencia de versiones XML del SDK, que no impidió la compilación. No hay Android conectado en flutter devices (Windows, Chrome y Edge); apertura física y recorrido del S22 pendientes. No se simularon como pruebas físicas. Para validar: instalar el APK actualizado, habilitar GPS preciso, confirmar textos con la tecla Buscar, elegir candidato comparando con un punto conocido o seleccionar manualmente; analizar ruta e iniciar navegación. Como pasajero o en una prueba supervisada, comprobar giro al avanzar, estabilidad detenido, arrastre/recentrado y mensaje ante mala señal. Registrar texto, candidato seleccionado, coordenada esperada verificada y captura; no manipular el teléfono al conducir.

Se conserva rama, cambios de OAuth/cobertura, pubspec.lock previo y stash. Sin commit, push ni PR. Archivos de esta fase: lib/services/address_query.dart, geocoding_service.dart, place_suggestion_service.dart, location_service.dart; lib/navigation/navigation_camera.dart y navigation_session.dart; lib/screens/home/home_screen.dart; lib/widgets/map_search_panel.dart y route_planner_form.dart; test/services/address_navigation_audit_test.dart y geocoding_service_test.dart; test/navigation/navigation_camera_test.dart; test/screens/home/explicit_search_audit_test.dart, navigation_flow_test.dart, photon_flow_test.dart y route_flow_test.dart; test/fixtures/address-provider-audit.json y este documento. El estado completo incluye cambios locales anteriores; no todos se originaron en esta fase.
