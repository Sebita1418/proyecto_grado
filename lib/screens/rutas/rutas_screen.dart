import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/route_planner_controller.dart';
import '../../models/ruta_model.dart';
import '../../services/ruta_service.dart';
import '../../utils/polyline_decoder.dart';
import '../../utils/route_polyline.dart';
import '../../widgets/route_map.dart';
import '../../widgets/route_planner_form.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final RutaService _rutaService = RutaService();

  late final RoutePlannerController _routePlannerController;

  // Centro aproximado de Bucaramanga.
  static const LatLng _initialMapPosition = LatLng(7.1193, -73.1227);

  bool cargando = true;
  bool calculandoRuta = false;

  String? error;
  String? originError;
  String? destinationError;
  String? routeError;

  LatLng? _originPosition;
  LatLng? _destinationPosition;

  Set<Polyline> _routePolylines = const <Polyline>{};

  List<Ruta> rutas = [];
  List<Ruta> rutasFiltradas = [];

  final TextEditingController buscarController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  Set<Marker> get _routeMarkers {
    final markers = <Marker>{};

    if (_originPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_origin'),
          position: _originPosition!,
          infoWindow: const InfoWindow(title: 'Origen'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (_destinationPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_destination'),
          position: _destinationPosition!,
          infoWindow: const InfoWindow(title: 'Destino'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }

  @override
  void initState() {
    super.initState();

    _routePlannerController = RoutePlannerController.fromEnvironment();

    cargarRutas();
    buscarController.addListener(filtrarRutas);
  }

  Future<void> cargarRutas() async {
    try {
      final resultado = await _rutaService.obtenerRutasActivas();

      if (!mounted) return;

      setState(() {
        rutas = resultado;
        rutasFiltradas = resultado;
        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        cargando = false;
      });
    }
  }

  void filtrarRutas() {
    final texto = buscarController.text.trim().toLowerCase();

    setState(() {
      if (texto.isEmpty) {
        rutasFiltradas = List<Ruta>.from(rutas);
        return;
      }

      rutasFiltradas = rutas.where((ruta) {
        final nombre = ruta.nombre.toLowerCase();
        final origen = ruta.origen.toLowerCase();
        final destino = ruta.destino.toLowerCase();
        final descripcion = ruta.descripcion?.toLowerCase() ?? '';

        return nombre.contains(texto) ||
            origen.contains(texto) ||
            destino.contains(texto) ||
            descripcion.contains(texto);
      }).toList();
    });
  }

  Future<void> refrescar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    await cargarRutas();
  }

  void _seleccionarPunto(LatLng position) {
    setState(() {
      routeError = null;
      _routePolylines = const <Polyline>{};

      if (_originPosition == null) {
        _originPosition = position;

        originController.text =
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}';

        originError = null;
        return;
      }

      if (_destinationPosition == null) {
        _destinationPosition = position;

        destinationController.text =
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}';

        destinationError = null;
        return;
      }

      // Si ya existen ambos puntos, comienza una selección nueva.
      _routePlannerController.reset();

      _originPosition = position;
      _destinationPosition = null;

      originController.text =
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}';

      destinationController.clear();

      originError = null;
      destinationError = null;
    });
  }

  void _limpiarSeleccion() {
    _routePlannerController.reset();

    setState(() {
      _originPosition = null;
      _destinationPosition = null;

      _routePolylines = const <Polyline>{};

      originController.clear();
      destinationController.clear();

      originError = null;
      destinationError = null;
      routeError = null;
      calculandoRuta = false;
    });
  }

  Future<void> calcularRuta() async {
    setState(() {
      originError = _originPosition == null
          ? 'Selecciona el origen tocando el mapa.'
          : null;

      destinationError = _destinationPosition == null
          ? 'Selecciona el destino tocando el mapa.'
          : null;

      routeError = null;
    });

    final origin = _originPosition;
    final destination = _destinationPosition;

    if (origin == null || destination == null) {
      return;
    }

    setState(() {
      calculandoRuta = true;
      _routePolylines = const <Polyline>{};
    });

    await _routePlannerController.calculateRoute(
      originLatitude: origin.latitude,
      originLongitude: origin.longitude,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
    );

    if (!mounted) return;

    if (_routePlannerController.hasRoute) {
      final route = _routePlannerController.route!;

      try {
        final points = PolylineDecoder.decode(route.encodedPolyline);
        final polylines = RoutePolyline.build(points: points);

        setState(() {
          calculandoRuta = false;
          _routePolylines = polylines;
          routeError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ruta calculada: '
              '${route.distanceKilometers.toStringAsFixed(2)} km, '
              '${_formatearDuracion(route.duration)}.',
            ),
          ),
        );
      } on FormatException catch (e) {
        setState(() {
          calculandoRuta = false;
          _routePolylines = const <Polyline>{};
          routeError = 'No fue posible interpretar la ruta: ${e.message}';
        });
      }

      return;
    }

    setState(() {
      calculandoRuta = false;
      _routePolylines = const <Polyline>{};

      routeError =
          _routePlannerController.errorMessage ??
          'No fue posible calcular la ruta.';
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(routeError!)));
  }

  String _formatearDuracion(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    }

    if (hours > 0) {
      return '$hours h';
    }

    return '$minutes min';
  }

  @override
  void dispose() {
    buscarController.removeListener(filtrarRutas);

    buscarController.dispose();
    originController.dispose();
    destinationController.dispose();

    _routePlannerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas disponibles'), centerTitle: true),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _construirError()
          : _construirContenido(),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'No fue posible cargar las rutas.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: refrescar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    return RefreshIndicator(
      onRefresh: refrescar,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Planificación de rutas',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona el origen y el destino directamente en el mapa.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          RoutePlannerForm(
            originController: originController,
            destinationController: destinationController,
            onCalculate: calcularRuta,
            isLoading: calculandoRuta,
            originError: originError,
            destinationError: destinationError,
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mapa de ruta - Bucaramanga',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (_originPosition != null || _destinationPosition != null)
                TextButton.icon(
                  onPressed: calculandoRuta ? null : _limpiarSeleccion,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                ),
            ],
          ),

          const SizedBox(height: 10),

          RouteMap(
            initialPosition: _initialMapPosition,
            markers: _routeMarkers,
            polylines: _routePolylines,
            onTap: calculandoRuta ? null : _seleccionarPunto,
          ),

          const SizedBox(height: 12),

          _SelectionStatus(
            originSelected: _originPosition != null,
            destinationSelected: _destinationPosition != null,
          ),

          if (routeError != null) ...[
            const SizedBox(height: 12),
            _RouteErrorMessage(message: routeError!),
          ],

          const SizedBox(height: 28),

          const Divider(),

          const SizedBox(height: 20),

          const Text(
            'Rutas disponibles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: buscarController,
            decoration: InputDecoration(
              hintText: 'Buscar ruta...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: buscarController.text.isNotEmpty
                  ? IconButton(
                      onPressed: buscarController.clear,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '${rutasFiltradas.length} ruta(s) disponible(s)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          if (rutasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.route_outlined, size: 65, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay rutas disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            ...rutasFiltradas.map(
              (ruta) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RutaCard(ruta: ruta),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionStatus extends StatelessWidget {
  const _SelectionStatus({
    required this.originSelected,
    required this.destinationSelected,
  });

  final bool originSelected;
  final bool destinationSelected;

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (!originSelected) {
      message = 'Toca el mapa para seleccionar el punto de origen.';
      icon = Icons.touch_app_outlined;
    } else if (!destinationSelected) {
      message = 'Origen seleccionado. Ahora selecciona el destino.';
      icon = Icons.location_on_outlined;
    } else {
      message = 'Origen y destino seleccionados. Ya puedes calcular la ruta.';
      icon = Icons.check_circle_outline;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }
}

class _RouteErrorMessage extends StatelessWidget {
  const _RouteErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _RutaCard extends StatelessWidget {
  const _RutaCard({required this.ruta});

  final Ruta ruta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 27,
              child: Icon(Icons.directions_bus_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Origen: ${ruta.origen}'),
                  const SizedBox(height: 6),
                  Text('Destino: ${ruta.destino}'),
                  if (ruta.descripcion != null &&
                      ruta.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      ruta.descripcion!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
