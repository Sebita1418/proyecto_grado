# transporte_inteligente

Punto de continuación: [baseline estable y siguiente incremento](docs/stable-baseline.md).

Incremento actual: [experiencia map-first y borrador geolocalizado](docs/map-first-experience.md).

La ubicación actual utiliza geolocalización del dispositivo solo mientras se usa la aplicación. En web requiere un contexto seguro (HTTPS o `localhost` durante desarrollo) y permiso del navegador. Si no está disponible, el usuario puede escribir el origen manualmente.

## Routing del prototipo

- OpenStreetMap (mediante `flutter_map`) muestra el mapa.
- GPS proporciona el origen actual cuando el usuario concede permiso; también se admite origen manual.
- Photon ofrece sugerencias de lugares. Si el usuario calcula con texto sin seleccionar una sugerencia, Nominatim geocodifica ese texto.
- OSRM calcula la ruta vehicular, su geometría de calles, distancia y duración estimada. Se solicita GeoJSON completo y se dibujan todos sus puntos.

El endpoint público `router.project-osrm.org` es un servidor de demostración y no constituye infraestructura de producción. Antes de desplegar un servicio estable hay que definir un endpoint gestionado y revisar su capacidad y disponibilidad.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
