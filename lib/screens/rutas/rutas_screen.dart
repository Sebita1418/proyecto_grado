import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/ruta_model.dart';
import '../../models/geocoding_result.dart';
import '../../models/place_suggestion.dart';
import '../../services/geocoding_service.dart';
import '../../services/place_suggestion_service.dart';
import '../../services/ruta_service.dart';
import '../../widgets/route_map.dart';
import '../../widgets/route_planner_form.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({
    super.key,
    this.loadRoutes,
    this.geocodingService,
    this.placeSuggestionService,
  });

  final Future<List<Ruta>> Function()? loadRoutes;
  final GeocodingService? geocodingService;
  final PlaceSuggestionService? placeSuggestionService;

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  late final Future<List<Ruta>> Function() _loadRoutes =
      widget.loadRoutes ?? RutaService().obtenerRutasActivas;
  late final GeocodingService _geocodingService =
      widget.geocodingService ?? GeocodingService();
  late final PlaceSuggestionService _placeSuggestionService =
      widget.placeSuggestionService ?? PlaceSuggestionService();

  static const LatLng _initialMapPosition = LatLng(7.119349, -73.122742);

  bool cargando = true;
  bool calculandoRuta = false;

  String? error;
  String? originError;
  String? destinationError;

  List<Ruta> rutas = [];
  List<Ruta> rutasFiltradas = [];
  GeocodingResult? origenGeocodificado;
  GeocodingResult? destinoGeocodificado;
  List<PlaceSuggestion> sugerenciasOrigen = [];
  List<PlaceSuggestion> sugerenciasDestino = [];
  PlaceSuggestion? origenSeleccionado;
  PlaceSuggestion? destinoSeleccionado;
  bool cargandoSugerenciasOrigen = false;
  bool cargandoSugerenciasDestino = false;
  String? errorSugerenciasOrigen;
  String? errorSugerenciasDestino;

  Timer? _debounceOrigen;
  Timer? _debounceDestino;
  int _solicitudOrigen = 0;
  int _solicitudDestino = 0;
  bool _actualizandoOrigen = false;
  bool _actualizandoDestino = false;
  String _ultimoTextoOrigen = '';
  String _ultimoTextoDestino = '';

  final TextEditingController buscarController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();

    cargarRutas();
    buscarController.addListener(filtrarRutas);
    originController.addListener(_alCambiarOrigen);
    destinationController.addListener(_alCambiarDestino);
  }

  Future<void> cargarRutas() async {
    try {
      final resultado = await _loadRoutes();

      if (!mounted) {
        return;
      }

      setState(() {
        rutas = resultado;
        rutasFiltradas = resultado;
        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

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

  void _alCambiarOrigen() {
    final text = originController.text;
    if (text == _ultimoTextoOrigen) return;
    _ultimoTextoOrigen = text;
    if (_actualizandoOrigen) return;
    _programarSugerencias(esOrigen: true);
  }

  void _alCambiarDestino() {
    final text = destinationController.text;
    if (text == _ultimoTextoDestino) return;
    _ultimoTextoDestino = text;
    if (_actualizandoDestino) return;
    _programarSugerencias(esOrigen: false);
  }

  void _programarSugerencias({required bool esOrigen}) {
    final controller = esOrigen ? originController : destinationController;
    final consulta = controller.text.trim();
    final solicitud = esOrigen ? ++_solicitudOrigen : ++_solicitudDestino;

    if (esOrigen) {
      _debounceOrigen?.cancel();
    } else {
      _debounceDestino?.cancel();
    }

    setState(() {
      if (esOrigen) {
        originError = null;
        origenSeleccionado = null;
        origenGeocodificado = null;
        sugerenciasOrigen = [];
        errorSugerenciasOrigen = null;
        cargandoSugerenciasOrigen = consulta.length >= 3;
      } else {
        destinationError = null;
        destinoSeleccionado = null;
        destinoGeocodificado = null;
        sugerenciasDestino = [];
        errorSugerenciasDestino = null;
        cargandoSugerenciasDestino = consulta.length >= 3;
      }
    });

    if (consulta.length < 3) return;

    final timer = Timer(const Duration(milliseconds: 450), () {
      _buscarSugerencias(
        consulta: consulta,
        solicitud: solicitud,
        esOrigen: esOrigen,
      );
    });

    if (esOrigen) {
      _debounceOrigen = timer;
    } else {
      _debounceDestino = timer;
    }
  }

  Future<void> _buscarSugerencias({
    required String consulta,
    required int solicitud,
    required bool esOrigen,
  }) async {
    try {
      final resultados = await _placeSuggestionService.search(consulta);
      if (!mounted || !_esSolicitudActual(solicitud, esOrigen)) return;

      setState(() {
        if (esOrigen) {
          sugerenciasOrigen = resultados;
          cargandoSugerenciasOrigen = false;
        } else {
          sugerenciasDestino = resultados;
          cargandoSugerenciasDestino = false;
        }
      });
    } on PlaceSuggestionException catch (error) {
      if (!mounted || !_esSolicitudActual(solicitud, esOrigen)) return;

      setState(() {
        if (esOrigen) {
          cargandoSugerenciasOrigen = false;
          errorSugerenciasOrigen = error.message;
        } else {
          cargandoSugerenciasDestino = false;
          errorSugerenciasDestino = error.message;
        }
      });
    }
  }

  bool _esSolicitudActual(int solicitud, bool esOrigen) {
    return solicitud == (esOrigen ? _solicitudOrigen : _solicitudDestino);
  }

  void _seleccionarSugerencia(
    PlaceSuggestion suggestion, {
    required bool esOrigen,
  }) {
    if (calculandoRuta) return;
    if (esOrigen) {
      _debounceOrigen?.cancel();
      _solicitudOrigen++;
      _actualizandoOrigen = true;
      originController.text = suggestion.displayText;
      originController.selection = TextSelection.collapsed(
        offset: originController.text.length,
      );
      _actualizandoOrigen = false;
    } else {
      _debounceDestino?.cancel();
      _solicitudDestino++;
      _actualizandoDestino = true;
      destinationController.text = suggestion.displayText;
      destinationController.selection = TextSelection.collapsed(
        offset: destinationController.text.length,
      );
      _actualizandoDestino = false;
    }

    setState(() {
      if (esOrigen) {
        origenSeleccionado = suggestion;
        origenGeocodificado = _resultadoDeSugerencia(suggestion);
        originError = null;
        sugerenciasOrigen = [];
        cargandoSugerenciasOrigen = false;
        errorSugerenciasOrigen = null;
      } else {
        destinoSeleccionado = suggestion;
        destinoGeocodificado = _resultadoDeSugerencia(suggestion);
        destinationError = null;
        sugerenciasDestino = [];
        cargandoSugerenciasDestino = false;
        errorSugerenciasDestino = null;
      }
    });
    FocusScope.of(context).unfocus();
  }

  GeocodingResult _resultadoDeSugerencia(PlaceSuggestion suggestion) {
    return GeocodingResult(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      displayName: suggestion.displayText,
    );
  }

  // Conserva la selección por tap y el reinicio de #16 con coordenadas OSM.
  void _seleccionarPunto(LatLng point) {
    if (calculandoRuta) return;
    if (origenSeleccionado != null && destinoSeleccionado != null) {
      _limpiarSeleccion();
    }
    _seleccionarSugerencia(
      PlaceSuggestion(
        name:
            '${point.latitude.toStringAsFixed(6)}, '
            '${point.longitude.toStringAsFixed(6)}',
        description: '',
        latitude: point.latitude,
        longitude: point.longitude,
      ),
      esOrigen: origenSeleccionado == null,
    );
  }

  void _limpiarSeleccion() {
    if (calculandoRuta) return;
    originController.clear();
    destinationController.clear();
  }

  void _cancelarSugerenciasPendientes() {
    _debounceOrigen?.cancel();
    _debounceDestino?.cancel();
    _solicitudOrigen++;
    _solicitudDestino++;
    sugerenciasOrigen = [];
    sugerenciasDestino = [];
    cargandoSugerenciasOrigen = false;
    cargandoSugerenciasDestino = false;
    errorSugerenciasOrigen = null;
    errorSugerenciasDestino = null;
  }

  Future<void> calcularRuta() async {
    if (calculandoRuta) return;

    final origen = originController.text.trim();
    final destino = destinationController.text.trim();

    setState(() {
      originError = origen.isEmpty ? 'Ingresa el punto de origen.' : null;

      destinationError = destino.isEmpty
          ? 'Ingresa el punto de destino.'
          : null;
    });

    if (origen.isEmpty || destino.isEmpty) {
      return;
    }

    setState(() {
      calculandoRuta = true;
      _cancelarSugerenciasPendientes();
      origenGeocodificado = null;
      destinoGeocodificado = null;
    });

    try {
      final origenEncontrado = origenSeleccionado != null
          ? _resultadoDeSugerencia(origenSeleccionado!)
          : await _geocodingService.search(origen);
      if (!mounted) return;
      if (origenEncontrado == null) {
        _mostrarMensaje('No se encontró el origen: $origen.');
        return;
      }

      final destinoEncontrado = destinoSeleccionado != null
          ? _resultadoDeSugerencia(destinoSeleccionado!)
          : await _geocodingService.search(destino);
      if (!mounted) return;
      if (destinoEncontrado == null) {
        _mostrarMensaje('No se encontró el destino: $destino.');
        return;
      }

      setState(() {
        origenGeocodificado = origenEncontrado;
        destinoGeocodificado = destinoEncontrado;
        origenSeleccionado = PlaceSuggestion(
          name: origen,
          description: '',
          latitude: origenEncontrado.latitude,
          longitude: origenEncontrado.longitude,
        );
        destinoSeleccionado = PlaceSuggestion(
          name: destino,
          description: '',
          latitude: destinoEncontrado.latitude,
          longitude: destinoEncontrado.longitude,
        );
      });
      _mostrarMensaje(
        'Origen y destino encontrados. El cálculo de ruta está pendiente.',
      );
    } on GeocodingException catch (error) {
      if (mounted) _mostrarMensaje(error.message);
    } finally {
      if (mounted) setState(() => calculandoRuta = false);
    }
  }

  void _mostrarMensaje(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _debounceOrigen?.cancel();
    _debounceDestino?.cancel();
    if (widget.geocodingService == null) _geocodingService.dispose();
    if (widget.placeSuggestionService == null) {
      _placeSuggestionService.dispose();
    }
    buscarController.dispose();
    originController.dispose();
    destinationController.dispose();

    super.dispose();
  }

  Widget? _construirSugerencias({required bool esOrigen}) {
    final sugerencias = esOrigen ? sugerenciasOrigen : sugerenciasDestino;
    final cargando = esOrigen
        ? cargandoSugerenciasOrigen
        : cargandoSugerenciasDestino;
    final error = esOrigen ? errorSugerenciasOrigen : errorSugerenciasDestino;

    if (!cargando && sugerencias.isEmpty && error == null) return null;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: cargando
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Buscando lugares...'),
                ],
              ),
            )
          : error != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error, style: const TextStyle(color: Colors.red)),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: sugerencias
                  .map(
                    (suggestion) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(suggestion.name),
                      subtitle: suggestion.description.isEmpty
                          ? null
                          : Text(suggestion.description),
                      onTap: () => _seleccionarSugerencia(
                        suggestion,
                        esOrigen: esOrigen,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
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
    final origen = origenGeocodificado;
    final destino = destinoGeocodificado;
    final List<Marker> marcadores = [
      if (origen != null)
        Marker(
          point: LatLng(origen.latitude, origen.longitude),
          width: 50,
          height: 50,
          child: Tooltip(
            message: 'Origen: ${origen.displayName}',
            child: const Icon(Icons.trip_origin, size: 38, color: Colors.green),
          ),
        ),
      if (destino != null)
        Marker(
          point: LatLng(destino.latitude, destino.longitude),
          width: 50,
          height: 50,
          child: Tooltip(
            message: 'Destino: ${destino.displayName}',
            child: const Icon(Icons.location_on, size: 42, color: Colors.red),
          ),
        ),
      if (origen == null && destino == null)
        Marker(
          point: _initialMapPosition,
          width: 50,
          height: 50,
          child: Tooltip(
            message: 'Bucaramanga',
            child: const Icon(Icons.location_on, size: 42, color: Colors.red),
          ),
        ),
    ];

    return RefreshIndicator(
      onRefresh: refrescar,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Consulta de rutas',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Busca lugares o toca el mapa para elegir origen y destino.',
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
            originSuggestions: _construirSugerencias(esOrigen: true),
            destinationSuggestions: _construirSugerencias(esOrigen: false),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.map_outlined),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mapa de Bucaramanga',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
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
            markers: marcadores,
            onTap: calculandoRuta ? null : _seleccionarPunto,
          ),
          const SizedBox(height: 8),
          Text(
            'El mapa muestra las ubicaciones seleccionadas. '
            'El cálculo vehicular de la ruta está pendiente; '
            'todavía no se muestran recorridos, distancias ni tiempos.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
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
